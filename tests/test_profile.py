"""Tests for the bundled MachineProfile registry."""

from __future__ import annotations

import pytest

from jura_connect.profile import (
    _parse_xml,
    iter_profiles,
    known_machine_names,
    list_profile_codes,
    load_profile,
    lookup_by_article_number,
    search_by_friendly_name,
)


def test_list_profile_codes_returns_88_machines():
    codes = list_profile_codes()
    # The APK we vendored ships 88 machine XMLs.
    assert len(codes) == 88
    # Must include the S8 EB (EF1091) and the legacy S8 (EF536).
    assert "EF1091" in codes
    assert "EF536" in codes


def test_ef1091_has_s8_eb_specific_products():
    """The S8 EB's product map differs from the legacy S8 — verify the
    codes the J.O.E. app actually shows for this machine."""
    p = load_profile("EF1091")
    # Smoke check: alert + product counts match the v1.6 XML.
    assert len(p.alerts) >= 50
    assert len(p.products) >= 17
    # Per-EF code differences from the EF536 baseline.
    assert p.product_by_code[0x2B].name == "cortado"
    assert p.product_by_code[0x2C].name == "sweet_latte"
    assert p.product_by_code[0x2E].name == "flat_white"
    assert p.product_by_code[0x30].name == "espresso_doppio"
    # The S8 EB uses 0x31/0x36 for the doubles (vs 0x12/0x13 on EF536).
    assert p.product_by_code[0x31].name == "2_espressi"
    assert p.product_by_code[0x36].name == "2_coffee"
    # No PROGRAMMODE in the EF1091 XML.
    assert p.has_pmode is False


def test_alert_severity_lifted_from_xml_type_attribute():
    p = load_profile("EF1091")
    # 'no beans' is Type="info" => severity "info".
    assert p.alert_by_bit[10].name == "no_beans"
    assert p.alert_by_bit[10].severity == "info"
    # 'fill water' is Type="block" => severity "error".
    assert p.alert_by_bit[1].name == "fill_water"
    assert p.alert_by_bit[1].severity == "error"
    # 'cappu rinse alert' is Type="ip" => severity "process".
    assert p.alert_by_bit[35].name == "cappu_rinse_alert"
    assert p.alert_by_bit[35].severity == "process"


def test_ef1069_maps_high_byte7_status_bits():
    """The J8 (SAS / EF1069) status frame carries bits in byte 7 that the
    EF536 baseline codebook (which stops at bit 38) doesn't know about.
    These are what the J8's @TF: frame actually exercises, so the profile
    must define them. See makefu/jura-connect-hass#3."""
    p = load_profile("EF1069")
    # bit 54 is set in every J8 frame at idle ("ML/OZ status").
    assert p.alert_by_bit[54].name == "ml_oz_status"
    assert p.alert_by_bit[54].severity == "info"
    # bit 56 toggles when a cup is placed under the coffee eye.
    assert p.alert_by_bit[56].name == "coffee_eye_cup_detected"
    assert p.alert_by_bit[56].severity == "info"


def test_unknown_profile_code_raises():
    with pytest.raises(KeyError):
        load_profile("EF_NOT_A_REAL_MACHINE")


def test_iter_profiles_covers_everything_without_crashing():
    """Every bundled XML must parse without an exception."""
    seen = list(iter_profiles())
    # 88 codes; at least the parseable subset must be non-trivial.
    assert len(seen) >= 80
    assert any(p.code == "EF1091" for p in seen)


def test_lookup_by_article_number_finds_s8_eb():
    entry = lookup_by_article_number(15480)
    assert entry is not None
    assert entry.friendly_name == "S8 (EB)"
    assert entry.ef_code == "EF1091"


def test_search_by_friendly_name_substring_match():
    rows = search_by_friendly_name("S8 (EB)")
    # 15480 (EF1091) and 15482 (EF1151) are both badged "S8 (EB)".
    codes = {r.ef_code for r in rows}
    assert "EF1091" in codes
    assert "EF1151" in codes
    # The result deduplicates per (friendly_name, ef_code) pair.
    assert len(rows) == 2


def test_known_machine_names_is_sorted_and_unique():
    names = known_machine_names()
    assert names == sorted(names)
    assert len(names) == len(set(names))


def test_parse_xml_handles_default_namespace():
    """The Jura XMLs use a default namespace; the loader must strip it."""
    text = """<?xml version="1.0"?>
<JOE Version="2" Group="TEST" xmlns="http://www.top-tronic.com">
  <PRODUCTS>
    <PRODUCT Code="02" Name="Espresso"/>
  </PRODUCTS>
  <ALERTS>
    <ALERT Bit="0" Name="insert tray" Type="block"/>
    <ALERT Bit="10" Name="no beans" Type="info"/>
  </ALERTS>
</JOE>
"""
    p = _parse_xml(text, code="TEST", version="1.0")
    assert len(p.alerts) == 2
    assert p.alert_by_bit[0].severity == "error"
    assert p.alert_by_bit[10].severity == "info"
    assert p.product_by_code[0x02].name == "espresso"
