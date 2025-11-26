import requests
import argparse
from collections import Counter

def main():
  parser = argparse.ArgumentParser(description="Test ALB distribution.")
  parser.add_argument(
    "--url",
    required=True,
    help="ALB URL leading to /info.json"
  )
  parser.add_argument(
    "--requests",
    type=int,
    default=50,
    help="Number of requests to perform (default 50)"
  )

  args = parser.parse_args()

  counts = Counter()

  print(f"Querying ALB: {args.url}")
  print(f"Sending {args.requests} requests...\n")

  for i in range(args.requests):
    try:
      r = requests.get(args.url, timeout=2)
      r.raise_for_status()
      data = r.json()
      hostname = data.get("hostname", "unknown")
      counts[hostname] += 1
    except Exception as e:
      print(f"Request {i} failed: {e}")

  print("\n=== Load balancer calls results ===")
  for host, count in counts.items():
    print(f"{host}: {count} requests")

if __name__ == "__main__":
  main()
