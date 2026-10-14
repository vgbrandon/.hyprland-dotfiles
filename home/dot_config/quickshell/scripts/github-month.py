#!/usr/bin/env python3
"""Actividad de GitHub de un mes, día por día (para el panel de GitHub de Quickshell).

Uso: github-month.py AAAA-MM
Imprime un JSON: { month, days: { "AAAA-MM-DD": { date, commits: [{repo, sha,
message, url, time}], pullRequests / issues / reviews: [{repo, title, url}] } } }.

Primero pregunta a GitHub (GraphQL) en qué repositorios hubo commits ese mes, y sus
PRs, issues y revisiones; luego pide los commits de cada repositorio (REST, con
paginación), así salen también los privados. Los días son en hora local.
"""
import json
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone

QUERY = """
query($from: DateTime!, $to: DateTime!) {
  viewer {
    login
    contributionsCollection(from: $from, to: $to) {
      commitContributionsByRepository(maxRepositories: 50) {
        repository { nameWithOwner }
      }
      pullRequestContributions(first: 100) { nodes { occurredAt pullRequest { title url repository { nameWithOwner } } } }
      issueContributions(first: 100) { nodes { occurredAt issue { title url repository { nameWithOwner } } } }
      pullRequestReviewContributions(first: 100) { nodes { occurredAt pullRequest { title url repository { nameWithOwner } } } }
    }
  }
}
"""

LOCAL = timezone(timedelta(seconds=time.localtime().tm_gmtoff))


def gh(*args):
    out = subprocess.run(["gh", *args], capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def iso(d):
    return d.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def local_date(stamp):
    """Fecha local ("AAAA-MM-DD") de una hora ISO de GitHub."""
    return datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone(LOCAL).strftime("%Y-%m-%d")


def main():
    month = sys.argv[1]
    start = datetime.strptime(month + "-01", "%Y-%m-%d").replace(tzinfo=LOCAL)
    end = (start + timedelta(days=32)).replace(day=1) - timedelta(seconds=1)

    viewer = gh("api", "graphql", "-f", f"query={QUERY}", "-f", f"from={iso(start)}", "-f", f"to={iso(end)}")["data"]["viewer"]
    coll = viewer["contributionsCollection"]

    days = {}

    def day(date):
        return days.setdefault(date, {"date": date, "commits": [], "pullRequests": [], "issues": [], "reviews": []})

    for entry in coll["commitContributionsByRepository"]:
        repo = entry["repository"]["nameWithOwner"]
        try:
            # --slurp: todas las páginas en una lista de listas
            pages = gh("api", "--paginate", "--slurp",
                       f"repos/{repo}/commits?author={viewer['login']}&since={iso(start)}&until={iso(end)}&per_page=100")
        except subprocess.CalledProcessError:
            continue
        for c in (c for page in pages for c in page):
            stamp = c["commit"]["author"]["date"]
            day(local_date(stamp))["commits"].append({
                "repo": repo,
                "sha": c["sha"][:7],
                "message": c["commit"]["message"].split("\n")[0],
                "url": c["html_url"],
                "time": stamp,
            })

    for key, field, target in (("pullRequestContributions", "pullRequest", "pullRequests"),
                               ("issueContributions", "issue", "issues"),
                               ("pullRequestReviewContributions", "pullRequest", "reviews")):
        for n in coll[key]["nodes"]:
            item = n[field]
            day(local_date(n["occurredAt"]))[target].append(
                {"repo": item["repository"]["nameWithOwner"], "title": item["title"], "url": item["url"]})

    for d in days.values():
        d["commits"].sort(key=lambda c: c["time"], reverse=True)

    print(json.dumps({"month": month, "days": days}))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"month": sys.argv[1] if len(sys.argv) > 1 else "", "error": str(e)}))
