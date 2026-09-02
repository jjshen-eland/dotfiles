#!/usr/bin/env python3
"""Detect macOS PF network-isolation CIDRs that overlap local interfaces.

Exit contract:
  0  current interface subnets do not collide (or platform is not macOS)
  1  one or more collisions; container attach/create must stop
  2  proof input is unavailable or cannot be parsed; fail closed

The live check is read-only. It never changes PF, Docker, OrbStack, routes, or
interfaces. Fixture flags exist for deterministic cross-platform tests and are
clearly identified in output; they are not proof about the live host.
"""

from __future__ import annotations

import argparse
import ipaddress
import os
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ANCHOR = "com.apple.internet-sharing/network_isolation"
TABLE = "network_isolation_table_v4"
INTERFACE_RE = re.compile(r"^([^\s:]+):")
INET_RE = re.compile(
    r"^\s+inet\s+(?P<address>[0-9.]+)"
    r"(?:\s+-->\s+[0-9.]+)?\s+netmask\s+(?P<netmask>0x[0-9a-fA-F]+|[0-9.]+)"
)
PASS_RE = re.compile(
    r"\bpass\s+quick\s+on\s+(?P<interface>\S+)\s+inet\s+"
    r"from\s+(?P<source>\S+)\s+to\s+(?P<destination>\S+)"
)
PF_NOISE = (
    "No ALTQ support in kernel",
    "ALTQ related functions disabled",
)


class ProofUnavailable(RuntimeError):
    """Raised when the detector cannot establish a trustworthy comparison."""


@dataclass(frozen=True)
class LocalSubnet:
    interface: str
    address: ipaddress.IPv4Address
    network: ipaddress.IPv4Network


@dataclass(frozen=True)
class Collision:
    isolation: ipaddress.IPv4Network
    local: LocalSubnet


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description=(
            "Read-only check for overlap between OrbStack/macOS PF isolation "
            "CIDRs and local IPv4 interface subnets."
        )
    )
    result.add_argument("--ifconfig-file", type=Path, help="fixture ifconfig output")
    result.add_argument("--rules-file", type=Path, help="fixture PF anchor rules")
    result.add_argument("--table-file", type=Path, help="fixture PF table output")
    return result


def stop(reason: str, detail: str) -> int:
    print("verdict: STOP")
    print(f"reason: {reason}")
    print(f"detail: {detail}")
    print("action: do not treat this run as CIDR safety proof")
    print("action: obtain read-only ifconfig and PF table evidence, then rerun")
    print(
        "action: NEVER auto-delete PF entries; request authorization before "
        "restart or firewall changes"
    )
    return 2


def read_fixture(path: Path, label: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ProofUnavailable(f"cannot read {label} fixture {path}: {exc}") from exc


def command_path(name: str, fallback: str) -> str:
    # Prefer the immutable macOS system path before PATH. In particular, never
    # hand an attacker-controlled PATH lookup to sudo as the pfctl executable.
    if Path(fallback).is_file():
        return fallback
    found = shutil.which(name)
    if found:
        return found
    raise ProofUnavailable(f"required command is unavailable: {name}")


def run_read_only(command: list[str], label: str) -> str:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ProofUnavailable(f"cannot read {label}: {exc}") from exc
    if completed.returncode != 0:
        message = (completed.stderr or completed.stdout).strip().splitlines()
        summary = message[0] if message else f"exit {completed.returncode}"
        raise ProofUnavailable(f"cannot read {label}: {summary}")
    return completed.stdout


def live_inputs() -> tuple[str, str, str]:
    ifconfig = command_path("ifconfig", "/sbin/ifconfig")
    pfctl = command_path("pfctl", "/sbin/pfctl")
    pf_prefix: list[str]
    if os.geteuid() == 0:
        pf_prefix = [pfctl]
    else:
        sudo = command_path("sudo", "/usr/bin/sudo")
        pf_prefix = [sudo, "-n", pfctl]

    ifconfig_text = run_read_only([ifconfig, "-a"], "local interfaces")
    rules_text = run_read_only(
        [*pf_prefix, "-a", ANCHOR, "-sr"], "PF network-isolation rules"
    )
    table_text = run_read_only(
        [*pf_prefix, "-a", ANCHOR, "-t", TABLE, "-T", "show"],
        f"PF table {TABLE}",
    )
    return ifconfig_text, rules_text, table_text


def ipv4_network(address: str, netmask: str) -> ipaddress.IPv4Network:
    if netmask.lower().startswith("0x"):
        mask_number = int(netmask, 16)
        if not 0 <= mask_number <= 0xFFFFFFFF:
            raise ValueError("netmask is outside IPv4 range")
        netmask = str(ipaddress.IPv4Address(mask_number))
    return ipaddress.IPv4Network(f"{address}/{netmask}", strict=False)


def parse_local_subnets(text: str) -> list[LocalSubnet]:
    interface: str | None = None
    records: set[LocalSubnet] = set()
    for line in text.splitlines():
        interface_match = INTERFACE_RE.match(line)
        if interface_match:
            interface = interface_match.group(1)
            continue
        inet_match = INET_RE.match(line)
        if not interface or not inet_match:
            continue
        try:
            address = ipaddress.IPv4Address(inet_match.group("address"))
            network = ipv4_network(
                inet_match.group("address"), inet_match.group("netmask")
            )
        except ValueError as exc:
            raise ProofUnavailable(
                f"invalid IPv4 data on interface {interface}: {exc}"
            ) from exc
        records.add(LocalSubnet(interface, address, network))
    if not records:
        raise ProofUnavailable("ifconfig contains no parseable IPv4 interface subnet")
    return sorted(records, key=lambda item: (item.interface, int(item.network.network_address)))


def parse_isolation_cidrs(text: str) -> list[ipaddress.IPv4Network]:
    networks: set[ipaddress.IPv4Network] = set()
    unknown: list[str] = []
    for line in text.splitlines():
        value = line.strip()
        if not value or value in PF_NOISE:
            continue
        try:
            parsed = ipaddress.ip_network(value, strict=False)
        except ValueError:
            unknown.append(value)
            continue
        if not isinstance(parsed, ipaddress.IPv4Network):
            raise ProofUnavailable(f"unexpected non-IPv4 isolation entry: {value}")
        networks.add(parsed)
    if unknown:
        raise ProofUnavailable(f"unparseable PF table output: {unknown[0]}")
    return sorted(networks, key=lambda item: (int(item.network_address), item.prefixlen))


def parse_managed_pairs(
    text: str,
) -> set[tuple[str, ipaddress.IPv4Network]]:
    pairs: set[tuple[str, ipaddress.IPv4Network]] = set()
    for line in text.splitlines():
        match = PASS_RE.search(line)
        if not match or match.group("source") != match.group("destination"):
            continue
        try:
            network = ipaddress.ip_network(match.group("source"), strict=False)
        except ValueError:
            continue
        if isinstance(network, ipaddress.IPv4Network):
            pairs.add((match.group("interface"), network))
    return pairs


def compare(
    isolation_cidrs: list[ipaddress.IPv4Network],
    local_subnets: list[LocalSubnet],
    managed_pairs: set[tuple[str, ipaddress.IPv4Network]],
) -> tuple[list[Collision], int]:
    collisions: list[Collision] = []
    exemptions: set[tuple[str, ipaddress.IPv4Network]] = set()
    for isolation in isolation_cidrs:
        for local in local_subnets:
            if not isolation.overlaps(local.network):
                continue
            pair = (local.interface, local.network)
            if isolation == local.network and pair in managed_pairs:
                exemptions.add(pair)
                continue
            collisions.append(Collision(isolation, local))
    return collisions, len(exemptions)


def main() -> int:
    args = parser().parse_args()
    fixture_values = (args.ifconfig_file, args.rules_file, args.table_file)
    fixture_mode = any(value is not None for value in fixture_values)
    if fixture_mode and not all(value is not None for value in fixture_values):
        return stop(
            "PROOF_INPUT_UNAVAILABLE",
            "fixture mode requires --ifconfig-file, --rules-file, and --table-file",
        )

    if not fixture_mode and platform.system() != "Darwin":
        print("verdict: NOT_APPLICABLE")
        print("reason: MACOS_PF_ONLY")
        return 0

    try:
        if fixture_mode:
            ifconfig_text = read_fixture(args.ifconfig_file, "ifconfig")
            rules_text = read_fixture(args.rules_file, "PF rules")
            table_text = read_fixture(args.table_file, "PF table")
            source = "fixture (NOT live-host proof)"
        else:
            ifconfig_text, rules_text, table_text = live_inputs()
            source = "live macOS host"

        local_subnets = parse_local_subnets(ifconfig_text)
        isolation_cidrs = parse_isolation_cidrs(table_text)
        managed_pairs = parse_managed_pairs(rules_text)
        collisions, exemption_count = compare(
            isolation_cidrs, local_subnets, managed_pairs
        )
    except ProofUnavailable as exc:
        return stop("PROOF_INPUT_UNAVAILABLE", str(exc))

    print(f"source: {source}")
    print(f"checked-isolation-cidrs: {len(isolation_cidrs)}")
    print(f"checked-local-subnets: {len(local_subnets)}")
    print(f"managed-exemptions: {exemption_count}")

    if not collisions:
        print("verdict: CLEAN")
        print(
            "scope: current PF isolation entries vs local interface subnets only; "
            "routed/production/candidate CIDRs still require separate preflight"
        )
        return 0

    print("verdict: STOP")
    print("reason: NETWORK_ISOLATION_COLLISION")
    for collision in collisions:
        print(
            "collision: "
            f"isolation={collision.isolation} "
            f"interface={collision.local.interface} "
            f"local={collision.local.network} "
            f"address={collision.local.address}"
        )
    print("action: STOP container attach/create until every collision is resolved")
    print("action: inspect the owning Docker/OrbStack network read-only and preserve evidence")
    print("action: use auto allocation plus DNS/test config instead of copied LAN CIDRs")
    print("action: if no owning network exists, report a stale isolation entry")
    print(
        "action: NEVER auto-delete PF entries; request authorization before restart "
        "or firewall changes"
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
