#!/usr/bin/env python3
"""
Analyze the final effect of a Ceph reweight by calculating total disk usage per OSD
once backfilling is finished.

Usage: 
  python3 predict-rook-pgmap.py                    # Fetch data directly from kubectl
"""

import json
import sys
import subprocess
from collections import defaultdict


def fetch_pg_data():
    """
    Fetch PG data directly from kubectl rook-ceph ceph pg dump_json
    
    Returns:
        dict: The parsed JSON data from kubectl command
    """
    try:
        print("Fetching PG data from kubectl rook-ceph ceph pg dump_json...", file=sys.stderr)
        result = subprocess.run(
            ['kubectl', 'rook-ceph', 'ceph', 'pg', 'dump_json'],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running kubectl command: {e}", file=sys.stderr)
        print(f"Command output: {e.stderr}", file=sys.stderr)
        raise
    except json.JSONDecodeError as e:
        print(f"Error parsing kubectl output as JSON: {e}", file=sys.stderr)
        raise


def fetch_osd_tree():
    """
    Fetch OSD tree data from kubectl rook-ceph ceph osd tree
    
    Returns:
        dict: Parsed OSD tree data with weight information
    """
    try:
        print("Fetching OSD tree data from kubectl rook-ceph ceph osd tree...", file=sys.stderr)
        result = subprocess.run(
            ['kubectl', 'rook-ceph', 'ceph', 'osd', 'tree', '--format', 'json'],
            capture_output=True,
            text=True,
            check=True
        )
        tree_data = json.loads(result.stdout)
        
        # Extract OSD weight information
        osd_weights = {}
        for node in tree_data.get('nodes', []):
            if node.get('type') == 'osd':
                osd_id = node.get('id')
                if osd_id is not None:
                    osd_weights[osd_id] = {
                        'weight': node.get('crush_weight', 0),
                        'reweight': node.get('reweight', 1.0)
                    }
        
        return osd_weights
    except subprocess.CalledProcessError as e:
        print(f"Error running kubectl osd tree command: {e}", file=sys.stderr)
        print(f"Command output: {e.stderr}", file=sys.stderr)
        raise
    except json.JSONDecodeError as e:
        print(f"Error parsing osd tree output as JSON: {e}", file=sys.stderr)
        raise


def get_usage_emoji(usage_percent):
    """Get emoji based on usage percentage"""
    if usage_percent < 80:
        return "🟢"
    elif usage_percent < 85:
        return "🟡"
    else:
        return "🔴"


def bytes_to_gib(bytes_val):
    """Convert bytes to GiB"""
    return bytes_val / (1024 ** 3)


def analyze_pg_distribution(pg_data):
    """
    Analyze PG distribution across OSDs and calculate projected disk usage.
    
    Args:
        pg_data: The parsed JSON data from 'ceph pg dump_json'
    
    Returns:
        dict: OSD statistics with projected usage
    """
    
    # Extract OSD stats to get total capacity per OSD
    osd_stats = {}
    for osd_stat in pg_data['pg_map']['osd_stats']:
        osd_id = osd_stat['osd']
        total_bytes = osd_stat['statfs']['total']
        current_used_bytes = osd_stat['statfs']['allocated']  # Current actual usage
        osd_stats[osd_id] = {
            'total_bytes': total_bytes,
            'current_used_bytes': current_used_bytes,
            'projected_used_bytes': 0,
            'pg_count': 0,
            'pending_pgs': 0,  # PGs in "up" but not in "acting"
            'weight': 0,
            'reweight': 1.0
        }
    
    # Process each PG and accumulate usage on target OSDs
    for pg_stat in pg_data['pg_map']['pg_stats']:
        # Skip PGs without proper stat_sum (some entries might be incomplete)
        if 'stat_sum' not in pg_stat or 'up' not in pg_stat or 'acting' not in pg_stat:
            continue
            
        pg_size_bytes = pg_stat['stat_sum']['num_bytes']
        up_osds = set(pg_stat['up'])
        acting_osds = set(pg_stat['acting'])
        
        # Add this PG's size to each OSD in the 'up' set (final target placement)
        for osd_id in up_osds:
            if osd_id in osd_stats:
                osd_stats[osd_id]['projected_used_bytes'] += pg_size_bytes
                osd_stats[osd_id]['pg_count'] += 1
                
                # Check if this PG is pending (in up but not in acting)
                if osd_id not in acting_osds:
                    osd_stats[osd_id]['pending_pgs'] += 1
    
    return osd_stats


def print_analysis(osd_stats):
    """Print the analysis results in a readable format"""
    
    print("OSD Usage Analysis (Current vs Projected after backfill):")
    print("=" * 115)
    print("OSD  PG#     Used/Total (GiB)    Current      Projected    Weight  Reweight")
    print("-" * 115)
    
    total_used_bytes = 0
    total_current_bytes = 0
    total_capacity_bytes = 0
    total_pending = 0
    
    for osd_id in sorted(osd_stats.keys()):
        stats = osd_stats[osd_id]
        current_used_gib = bytes_to_gib(stats['current_used_bytes'])
        projected_used_gib = bytes_to_gib(stats['projected_used_bytes'])
        total_gib = bytes_to_gib(stats['total_bytes'])
        
        current_usage_percent = (stats['current_used_bytes'] / stats['total_bytes']) * 100 if stats['total_bytes'] > 0 else 0
        projected_usage_percent = (stats['projected_used_bytes'] / stats['total_bytes']) * 100 if stats['total_bytes'] > 0 else 0
        
        current_emoji = get_usage_emoji(current_usage_percent)
        projected_emoji = get_usage_emoji(projected_usage_percent)
        
        # Format with manual spacing for alignment
        osd_col = f"{osd_id}"
        
        # PG count with pending indicator
        pg_display = f"{stats['pg_count']}"
        if stats['pending_pgs'] > 0:
            pg_display += f" ➕{stats['pending_pgs']}"
        pg_col = pg_display
        
        usage_col = f"{projected_used_gib:.1f}/{total_gib:.1f}"
        current_col = f"{current_emoji}{current_usage_percent:.1f}%"
        projected_col = f"{projected_emoji}{projected_usage_percent:.1f}%"
        weight_col = f"{stats['weight']:.3f}"
        reweight_col = f"{stats['reweight']:.3f}"
        
        print(f"{osd_col:>3}  {pg_col:<7}  {usage_col:<18} {current_col:<11} {projected_col:<12} {weight_col:>6}  {reweight_col:>7}")
        
        total_used_bytes += stats['projected_used_bytes']
        total_current_bytes += stats['current_used_bytes']
        total_capacity_bytes += stats['total_bytes']
        total_pending += stats['pending_pgs']
    
    print("-" * 115)
    total_current_gib = bytes_to_gib(total_current_bytes)
    total_used_gib = bytes_to_gib(total_used_bytes)
    total_capacity_gib = bytes_to_gib(total_capacity_bytes)
    
    current_overall_percent = (total_current_bytes / total_capacity_bytes) * 100 if total_capacity_bytes > 0 else 0
    projected_overall_percent = (total_used_bytes / total_capacity_bytes) * 100 if total_capacity_bytes > 0 else 0
    
    current_total_emoji = get_usage_emoji(current_overall_percent)
    projected_total_emoji = get_usage_emoji(projected_overall_percent)
    
    # Total row with pending count
    total_pg_display = ""
    if total_pending > 0:
        total_pg_display = f"➕{total_pending}"
    
    total_usage_col = f"{total_used_gib:.1f}/{total_capacity_gib:.1f}"
    total_current_col = f"{current_total_emoji}{current_overall_percent:.1f}%"
    total_projected_col = f"{projected_total_emoji}{projected_overall_percent:.1f}%"
    
    print(f"{'TOT':>3}  {total_pg_display:<7}  {total_usage_col:<18} {total_current_col:<11} {total_projected_col:<12} {'':>6}  {'':>7}")
    
    # Calculate balance metrics
    current_usage_percentages = []
    projected_usage_percentages = []
    for stats in osd_stats.values():
        if stats['total_bytes'] > 0:
            current_usage_percentages.append((stats['current_used_bytes'] / stats['total_bytes']) * 100)
            projected_usage_percentages.append((stats['projected_used_bytes'] / stats['total_bytes']) * 100)
    
    if projected_usage_percentages:
        current_min = min(current_usage_percentages) if current_usage_percentages else 0
        current_max = max(current_usage_percentages) if current_usage_percentages else 0
        current_variance = current_max - current_min
        
        proj_min = min(projected_usage_percentages)
        proj_max = max(projected_usage_percentages)
        proj_variance = proj_max - proj_min
        
        print(f"\nBalance Analysis:")
        print(f"  Current variance: {current_variance:.1f}% (min: {current_min:.1f}%, max: {current_max:.1f}%)")
        print(f"  Projected variance: {proj_variance:.1f}% (min: {proj_min:.1f}%, max: {proj_max:.1f}%)")
        
        if proj_variance < current_variance:
            print(f"  ✓ Reweight improved balance by {current_variance - proj_variance:.1f}%")
        elif proj_variance > current_variance:
            print(f"  ⚠ Reweight worsened balance by {proj_variance - current_variance:.1f}%")
        else:
            print("  → Reweight had no effect on balance")
            
        if proj_variance < 5:
            print("  ✓ Good projected balance (variance < 5%)")
        elif proj_variance < 10:
            print("  ⚠ Moderate projected imbalance (variance 5-10%)")
        else:
            print("  ✗ Poor projected balance (variance > 10%)")
            
        # Show pending movement summary
        if total_pending > 0:
            print(f"\nPending Movements:")
            print(f"  Total PGs awaiting movement: {total_pending}")
            print(f"  ➕ = PGs scheduled to move to this OSD (backfill pending)")


def main():
    """Main function"""
    try:
        # Fetch data directly from kubectl
        pg_data = fetch_pg_data()
        osd_weights = fetch_osd_tree()
        
        # Analyze the data
        osd_stats = analyze_pg_distribution(pg_data)
        
        # Merge weight information
        for osd_id in osd_stats:
            if osd_id in osd_weights:
                osd_stats[osd_id]['weight'] = osd_weights[osd_id]['weight']
                osd_stats[osd_id]['reweight'] = osd_weights[osd_id]['reweight']
        
        if not osd_stats:
            print("No OSD stats found in the data", file=sys.stderr)
            sys.exit(1)
        
        # Print results
        print_analysis(osd_stats)
        
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON - {e}", file=sys.stderr)
        sys.exit(1)
    except KeyError as e:
        print(f"Error: Missing expected key in data - {e}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error: kubectl command failed - {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()