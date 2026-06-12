#!/usr/bin/env python3
"""Generate Hairmap catalog seed SQL from salon and stylist CSV files.

The script prints SQL only; it does not connect to Supabase or require service keys.
Usage:
  python3 tools/generate_catalog_seed_sql.py \
    --salons templates/salon_import_template.csv \
    --stylists templates/stylist_import_template.csv > /tmp/hairmap_seed.sql
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def sql(value: object) -> str:
    if value is None:
        return "null"
    text = str(value).strip()
    if text == "":
        return "null"
    return "'" + text.replace("'", "''") + "'"


def sql_int(value: str, fallback: int = 0) -> str:
    text = (value or "").strip()
    return str(int(text)) if text else str(fallback)


def sql_float(value: str, fallback: float = 0) -> str:
    text = (value or "").strip()
    return str(float(text)) if text else str(fallback)


def sql_bool(value: str) -> str:
    return "true" if (value or "").strip().lower() in {"true", "1", "yes", "y"} else "false"


def sql_array(value: str) -> str:
    items = [item.strip() for item in (value or "").split("|") if item.strip()]
    if not items:
        return "'{}'::text[]"
    return "array[" + ", ".join(sql(item) for item in items) + "]"


def slug(*parts: str) -> str:
    raw = "-".join(part for part in parts if part)
    allowed = []
    for char in raw.lower().replace(" ", "-"):
        allowed.append(char if char.isalnum() or char == "-" else "-")
    return "-".join("".join(allowed).split("-"))[:96]


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def emit_salons(rows: list[dict[str, str]]) -> list[str]:
    statements: list[str] = []
    for row in rows:
        statements.append(
            "insert into public.salons "
            "(id, name, location, distance, rating, tags, open_hours, phone, start_price, image_url, is_featured, display_order) "
            f"values ({sql(row.get('salon_id'))}, {sql(row.get('name'))}, {sql(row.get('location'))}, "
            f"{sql_float(row.get('distance', '0'))}, {sql_float(row.get('rating', '5'))}, {sql_array(row.get('tags', ''))}, "
            f"{sql(row.get('open_hours'))}, {sql(row.get('phone'))}, {sql_int(row.get('start_price', '0'))}, "
            f"{sql(row.get('image_url'))}, {sql_bool(row.get('is_featured', 'false'))}, {sql_int(row.get('display_order', '100'))}) "
            "on conflict (id) do update set "
            "name = excluded.name, location = excluded.location, distance = excluded.distance, rating = excluded.rating, "
            "tags = excluded.tags, open_hours = excluded.open_hours, phone = excluded.phone, start_price = excluded.start_price, "
            "image_url = excluded.image_url, is_featured = excluded.is_featured, display_order = excluded.display_order;"
        )
        for index in range(1, 11):
            title = (row.get(f"work_{index}_title") or "").strip()
            image_url = (row.get(f"work_{index}_image_url") or "").strip()
            if title and image_url:
                work_id = slug(row.get("salon_id", ""), "work", str(index), title)
                statements.append(
                    "insert into public.salon_portfolio_works (id, salon_id, title, image_url, display_order) "
                    f"values ({sql(work_id)}, {sql(row.get('salon_id'))}, {sql(title)}, {sql(image_url)}, {index}) "
                    "on conflict (id) do update set title = excluded.title, image_url = excluded.image_url, display_order = excluded.display_order;"
                )
    return statements


def emit_stylists(rows: list[dict[str, str]]) -> list[str]:
    statements: list[str] = []
    for row in rows:
        statements.append(
            "insert into public.stylists "
            "(id, salon_id, name, title, rating, reviews_count, languages, experience, specialties, avatar_url, bio, base_price, is_featured, display_order) "
            f"values ({sql(row.get('stylist_id'))}, {sql(row.get('salon_id'))}, {sql(row.get('name'))}, {sql(row.get('title'))}, "
            f"{sql_float(row.get('rating', '5'))}, {sql_int(row.get('reviews_count', '0'))}, {sql(row.get('languages'))}, "
            f"{sql(row.get('experience'))}, {sql_array(row.get('specialties', ''))}, {sql(row.get('avatar_url'))}, "
            f"{sql(row.get('bio'))}, {sql_int(row.get('base_price', '0'))}, {sql_bool(row.get('is_featured', 'false'))}, "
            f"{sql_int(row.get('display_order', '100'))}) "
            "on conflict (id) do update set "
            "salon_id = excluded.salon_id, name = excluded.name, title = excluded.title, languages = excluded.languages, "
            "experience = excluded.experience, specialties = excluded.specialties, avatar_url = excluded.avatar_url, bio = excluded.bio, "
            "base_price = excluded.base_price, is_featured = excluded.is_featured, display_order = excluded.display_order;"
        )
        for index in range(1, 11):
            service_name = (row.get(f"service_{index}_name") or "").strip()
            if service_name:
                service_id = slug(row.get("stylist_id", ""), "service", str(index), service_name)
                statements.append(
                    "insert into public.services (id, stylist_id, name, category, duration, description, price, display_order) "
                    f"values ({sql(service_id)}, {sql(row.get('stylist_id'))}, {sql(service_name)}, "
                    f"{sql(row.get(f'service_{index}_category'))}, {sql_int(row.get(f'service_{index}_duration', '60'))}, "
                    f"{sql(row.get(f'service_{index}_description'))}, {sql_int(row.get(f'service_{index}_price', '0'))}, {index}) "
                    "on conflict (id) do update set name = excluded.name, category = excluded.category, duration = excluded.duration, "
                    "description = excluded.description, price = excluded.price, display_order = excluded.display_order;"
                )
            title = (row.get(f"work_{index}_title") or "").strip()
            image_url = (row.get(f"work_{index}_image_url") or "").strip()
            if title and image_url:
                work_id = slug(row.get("stylist_id", ""), "work", str(index), title)
                statements.append(
                    "insert into public.portfolio_works (id, stylist_id, title, image_url, display_order) "
                    f"values ({sql(work_id)}, {sql(row.get('stylist_id'))}, {sql(title)}, {sql(image_url)}, {index}) "
                    "on conflict (id) do update set title = excluded.title, image_url = excluded.image_url, display_order = excluded.display_order;"
                )
    return statements


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--salons", type=Path, required=True)
    parser.add_argument("--stylists", type=Path, required=True)
    args = parser.parse_args()

    statements = ["begin;"]
    statements.extend(emit_salons(read_rows(args.salons)))
    statements.extend(emit_stylists(read_rows(args.stylists)))
    statements.append("commit;")
    print("\n\n".join(statements))


if __name__ == "__main__":
    main()
