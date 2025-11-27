import argparse
import requests
from collections import Counter
from bs4 import BeautifulSoup

def extract_hostname(html):
  """Parses the hostname from the HTML body."""
  soup = BeautifulSoup(html, "html.parser")
  p_tags = soup.find_all("p")
  for p in p_tags:
    if "Hostname:" in p.text:
      return p.text.replace("Hostname:", "").strip()
  return "unknown"

def run_test(url, requests_count):
  _results = Counter()

  for i in range(requests_count):
    try:
      resp = requests.get(url, timeout=2)
      hostname = extract_hostname(resp.text)
      _results[hostname] += 1
    except Exception as e:
      _results["error"] += 1

  return _results

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Load-balance tester for NLB")
  parser.add_argument("--url", required=True, help="NLB DNS name or URL")
  parser.add_argument("--n", type=int, default=200, help="Number of requests")
  args = parser.parse_args()

  print(f"Running {args.n} requests against {args.url}")
  results = run_test(args.url, args.n)

  print("\n=== Results ===")
  total = sum(results.values())
  for k, v in results.items():
    pct = (v / total) * 100
    print(f"{k:20s}: {v:5d}  ({pct:5.1f}%)")
