#!/usr/bin/env python3
"""
Add continent information to NDJSON records based on country.
"""
import argparse
import json
import sys

import zstandard as zstd

# Continent to countries mapping
# Based on Pathoplexus country list (https://github.com/pathoplexus/pathoplexus/blob/main/loculus_values/values.yaml)
CONTINENT_COUNTRIES = {
    "Africa": [
        "Algeria", "Angola", "Bassas da India", "Belgian Congo", "Benin", "Botswana",
        "Burkina Faso", "Burundi", "Cameroon", "Cape Verde", "Central African Republic",
        "Chad", "Comoros", "Congo", "Cote d'Ivoire", "Democratic Republic of the Congo",
        "Djibouti", "Egypt", "Equatorial Guinea", "Eritrea", "Eswatini", "Ethiopia",
        "Europa Island", "Gabon", "Gambia", "Ghana", "Glorioso Islands", "Guinea",
        "Guinea-Bissau", "Juan de Nova Island", "Kenya", "Lesotho", "Liberia", "Libya",
        "Madagascar", "Malawi", "Mali", "Mauritania", "Mauritius", "Mayotte", "Morocco",
        "Mozambique", "Namibia", "Niger", "Nigeria", "Republic of the Congo", "Reunion",
        "Rwanda", "Sao Tome and Principe", "Senegal", "Seychelles", "Sierra Leone",
        "Somalia", "South Africa", "South Sudan", "Sudan", "Swaziland", "Tanzania",
        "Togo", "Tromelin Island", "Tunisia", "Uganda", "Western Sahara", "Zaire",
        "Zambia", "Zimbabwe",
    ],
    "Asia": [
        "Afghanistan", "Armenia", "Azerbaijan", "Bahrain", "Bangladesh", "Bhutan",
        "Brunei", "Burma", "Cambodia", "China", "Christmas Island", "Cocos Islands",
        "East Timor", "Gaza Strip", "Georgia", "Hong Kong", "India", "Indonesia",
        "Iran", "Iraq", "Israel", "Japan", "Jordan", "Kazakhstan", "Korea", "Kuwait",
        "Kyrgyzstan", "Laos", "Lebanon", "Macau", "Malaysia", "Maldives", "Mongolia",
        "Myanmar", "Nepal", "North Korea", "Oman", "Pakistan", "Palestine",
        "Palestinian Territory", "Paracel Islands", "Philippines", "Qatar",
        "Saudi Arabia", "Singapore", "South Korea", "Spratly Islands", "Sri Lanka",
        "State of Palestine", "Syria", "Taiwan", "Tajikistan", "Thailand",
        "Timor-Leste", "Turkey", "Turkmenistan", "United Arab Emirates", "Uzbekistan",
        "Viet Nam", "West Bank", "Yemen",
    ],
    "Europe": [
        "Albania", "Andorra", "Austria", "Belarus", "Belgium", "Bosnia and Herzegovina",
        "Bulgaria", "Croatia", "Cyprus", "Czech Republic", "Czechia", "Czechoslovakia",
        "Denmark", "Estonia", "Faroe Islands", "Finland", "France", "Germany",
        "Gibraltar", "Greece", "Guernsey", "Hungary", "Iceland", "Ireland",
        "Isle of Man", "Italy", "Jan Mayen", "Jersey", "Kosovo", "Latvia",
        "Liechtenstein", "Lithuania", "Luxembourg", "Macedonia", "Malta", "Moldova",
        "Monaco", "Montenegro", "Netherlands", "North Macedonia", "Norway", "Poland",
        "Portugal", "Romania", "Russia", "San Marino", "Serbia", "Serbia and Montenegro",
        "Slovakia", "Slovenia", "Spain", "Svalbard", "Sweden", "Switzerland",
        "The former Yugoslav Republic of Macedonia", "Ukraine", "United Kingdom",
        "USSR", "Yugoslavia",
    ],
    "North America": [
        "Anguilla", "Antigua and Barbuda", "Aruba", "Bahamas", "Barbados", "Belize",
        "Bermuda", "British Virgin Islands", "Canada", "Cayman Islands",
        "Clipperton Island", "Costa Rica", "Cuba", "Curacao", "Dominica",
        "Dominican Republic", "El Salvador", "Greenland", "Grenada", "Guadeloupe",
        "Guatemala", "Haiti", "Honduras", "Jamaica", "Martinique", "Mexico",
        "Montserrat", "Nicaragua", "Panama", "Puerto Rico", "Saint Barthelemy",
        "Saint Kitts and Nevis", "Saint Lucia", "Saint Martin", "Saint Pierre and Miquelon",
        "Saint Vincent and the Grenadines", "Sint Maarten", "Trinidad and Tobago",
        "Turks and Caicos Islands", "USA", "Virgin Islands",
    ],
    "South America": [
        "Argentina", "Bolivia", "Brazil", "British Guiana", "Chile", "Colombia",
        "Ecuador", "Falkland Islands (Islas Malvinas)", "French Guiana", "Guyana",
        "Paraguay", "Peru", "South Georgia and the South Sandwich Islands", "Suriname",
        "Uruguay", "Venezuela",
    ],
    "Oceania": [
        "American Samoa", "Ashmore and Cartier Islands", "Australia", "Baker Island",
        "Borneo", "Cook Islands", "Coral Sea Islands", "Fiji", "French Polynesia",
        "Guam", "Heard Island and McDonald Islands", "Howland Island", "Jarvis Island",
        "Johnston Atoll", "Kerguelen Archipelago", "Kingman Reef", "Kiribati",
        "Line Islands", "Marshall Islands", "Micronesia", "Micronesia, Federated States of",
        "Midway Islands", "Nauru", "Navassa Island", "New Caledonia", "New Zealand",
        "Niue", "Norfolk Island", "Northern Mariana Islands", "Palau", "Palmyra Atoll",
        "Papua New Guinea", "Pitcairn Islands", "Samoa", "Solomon Islands", "Tokelau",
        "Tonga", "Tuvalu", "Vanuatu", "Wake Island", "Wallis and Futuna",
    ],
    "Antarctica": [
        "Antarctica", "Bouvet Island", "French Southern and Antarctic Lands",
    ],
}

# Special cases: oceans, seas, and other non-country locations (mapped to None)
SPECIAL_LOCATIONS = [
    "Arctic Ocean", "Atlantic Ocean", "Baltic Sea", "Indian Ocean",
    "Mediterranean Sea", "North Sea", "Pacific Ocean", "Ross Sea",
    "Southern Ocean", "Tasman Sea",
    # Also handle missing/unknown
    "missing",
]

# Build reverse lookup dict for fast lookups
COUNTRY_TO_CONTINENT = {}
for continent, countries in CONTINENT_COUNTRIES.items():
    for country in countries:
        COUNTRY_TO_CONTINENT[country] = continent

# Add special locations with None as continent
for location in SPECIAL_LOCATIONS:
    COUNTRY_TO_CONTINENT[location] = None


def get_continent(country):
    """
    Get continent for a country.

    Args:
        country: Country name string

    Returns:
        Continent name or None if country not found or is a special location (ocean, etc.)
    """
    if not country:
        return None

    # Direct lookup (includes explicit None for special locations)
    if country in COUNTRY_TO_CONTINENT:
        return COUNTRY_TO_CONTINENT[country]

    # Try case-insensitive lookup
    country_lower = country.lower()
    for known_country, cont in COUNTRY_TO_CONTINENT.items():
        if known_country.lower() == country_lower:
            return cont

    # Country not found - print warning to stderr but continue processing
    print(f"Warning: Unknown country '{country}'", file=sys.stderr)
    return None


def process_records(input_file, output_file):
    """
    Read NDJSON, add continent field, write output.

    Args:
        input_file: Path to input .ndjson.zst file
        output_file: Path to output .ndjson.zst file
    """
    dctx = zstd.ZstdDecompressor()
    cctx = zstd.ZstdCompressor()

    with open(input_file, 'rb') as ifh, open(output_file, 'wb') as ofh:
        with dctx.stream_reader(ifh) as reader, cctx.stream_writer(ofh) as writer:
            # Stream in chunks and process line by line
            buffer = b''
            chunk_size = 1024 * 1024  # 1MB chunks

            while True:
                chunk = reader.read(chunk_size)
                if not chunk:
                    break

                buffer += chunk

                # Process complete lines
                while b'\n' in buffer:
                    line_bytes, buffer = buffer.split(b'\n', 1)
                    line = line_bytes.decode('utf-8').strip()

                    if not line:
                        continue

                    record = json.loads(line)

                    # Add continent field based on country
                    country = record.get('geoLocCountry')
                    continent = get_continent(country)
                    record['geoLocContinent'] = continent

                    # Write modified record
                    output_line = json.dumps(record) + '\n'
                    writer.write(output_line.encode('utf-8'))

            # Process any remaining data in buffer
            if buffer.strip():
                line = buffer.decode('utf-8').strip()
                record = json.loads(line)
                country = record.get('geoLocCountry')
                continent = get_continent(country)
                record['geoLocContinent'] = continent
                output_line = json.dumps(record) + '\n'
                writer.write(output_line.encode('utf-8'))


def main():
    parser = argparse.ArgumentParser(
        description="Add continent field to NDJSON records based on country"
    )
    parser.add_argument(
        '--input',
        required=True,
        help='Input NDJSON file (compressed with zstd)'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Output NDJSON file (compressed with zstd)'
    )

    args = parser.parse_args()

    process_records(args.input, args.output)


if __name__ == '__main__':
    main()
