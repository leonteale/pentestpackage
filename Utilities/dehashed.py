import requests
import argparse
import sys
import csv
from pprint import pprint
from colorama import init, Fore, Style
from tabulate import tabulate
from textwrap import shorten

# Initialise colorama for coloured output
init(autoreset=True)

# Your DeHashed API key
API_KEY = "5Q+e0+q8tQFHlfTU11cGCx5FyzvvIJnn+4bzxJdybl1BZv0FbB6GcY4="

def search_dehashed(query: str):
    """Send a search query to the DeHashed API"""
    url = "https://api.dehashed.com/v2/search"
    headers = {
        "Content-Type": "application/json",
        "DeHashed-Api-Key": API_KEY
    }
    payload = {
        "query": query,
        "de_dupe": True
    }

    print(f"{Fore.CYAN}[*] Querying DeHashed for: {query}")
    response = requests.post(url, json=payload, headers=headers)

    if response.status_code == 200:
        print(f"{Fore.GREEN}[+] Results received")
        return response.json()
    else:
        print(f"{Fore.RED}[-] Error {response.status_code}: {response.text}")
        return None

def display_results(results: dict):
    """Display DeHashed results in a clean, colour-coded table."""
    entries = results.get("entries", [])
    entries.sort(key=lambda e: (e.get("email") or [""])[0])
    if not entries:
        print(f"{Fore.RED}[-] No entries found.")
        return

    print(f"\n{Fore.YELLOW}==== DeHashed Results ====\n")

    table_data = []

    for entry in entries:
        row = {
            "ID": entry.get("id", "")[:6] + "...",
            "Email": ", ".join(entry.get("email", [])) or "",
            "Username": ", ".join(entry.get("username", [])) or "",
            "Password": ", ".join(entry.get("password", [])) or "",
            "Hash": ", ".join(entry.get("hashed_password", [])) or "",
            "Database": entry.get("database_name", "")
        }

        # Colour and shorten
        if row["Password"]:
            row["Password"] = f"{Fore.GREEN}{shorten(row['Password'], width=30, placeholder='...')}{Style.RESET_ALL}"
        if row["Hash"]:
            row["Hash"] = f"{Fore.RED}{shorten(row['Hash'], width=50, placeholder='...')}{Style.RESET_ALL}"

        table_data.append(row)

    headers = {
        "ID": "ID",
        "Email": "Email",
        "Username": "Username",
        "Password": "Plaintext Password",
        "Hash": "Hashed Password(s)",
        "Database": "Database"
    }

    print(tabulate(table_data, headers=headers, tablefmt="fancy_grid"))

def display_full(results: dict):
    """Print full raw-style entry output with colour like original version."""
    entries = results.get("entries", [])
    if not entries:
        print(f"{Fore.RED}[-] No entries found.")
        return

    print(f"\n{Fore.YELLOW}==== DeHashed Results (Full View) ====\n")

    for entry in entries:
        print(f"{Fore.BLUE}--- Record ID: {entry.get('id', 'N/A')} ---")
        for key, value in entry.items():
            if key == "password":
                colour = Fore.GREEN
            elif key == "hashed_password":
                colour = Fore.RED
            else:
                colour = Fore.WHITE
            print(f"{colour}{key}: {value}")
        print("")

def flatten_entry(entry: dict) -> dict:
    """Flatten complex dict values (like lists) for CSV writing"""
    return {k: ", ".join(v) if isinstance(v, list) else v for k, v in entry.items()}

def save_to_csv(results: dict, filename: str):
    """Save results to a CSV file with specified column order."""
    entries = results.get("entries", [])
    if not entries:
        print(f"{Fore.YELLOW}[!] No entries to save to CSV.")
        return
    
    entries.sort(key=lambda e: (e.get("email") or [""])[0])

    # Define preferred column order
    preferred_order = [
        "email",
        "username",
        "password",
        "name",
        "ip_address",
        "address",
        "database_name",
        "id",
        "hashed_password"
    ]

    flat_entries = [flatten_entry(entry) for entry in entries]

    # Collect any unexpected keys
    all_keys = set(k for entry in flat_entries for k in entry.keys())
    extra_keys = [k for k in sorted(all_keys) if k not in preferred_order]

    # Final header order: preferred fields first, then extras
    final_header = preferred_order + extra_keys

    # Write to CSV
    with open(filename, mode='w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=final_header)
        writer.writeheader()
        for flat in flat_entries:
            writer.writerow(flat)

    print(f"{Fore.GREEN}[+] Results saved to CSV: {filename}")

def main():
    parser = argparse.ArgumentParser(
        description="DeHashed Lookup Tool (email or domain search)",
        epilog="Example: python dehashed.py --email test@example.com --csv output.csv"
    )
    parser.add_argument("--email", help="Search by email address")
    parser.add_argument("--domain", help="Search all emails on a domain (e.g. example.com)")
    parser.add_argument("--csv", help="Optional: save results to CSV file")
    parser.add_argument("--full", action="store_true", help="Display full unformatted results")

    args = parser.parse_args()

    # Ensure a valid search type is given
    if args.email:
        query = args.email
    elif args.domain:
        query = f"domain:{args.domain}"
    else:
        parser.print_help()
        sys.exit(1)

    results = search_dehashed(query)
    if results:
        if args.full:
            display_full(results)
        else:
            display_results(results)

        if args.csv:
            save_to_csv(results, args.csv)

if __name__ == "__main__":
    main()
