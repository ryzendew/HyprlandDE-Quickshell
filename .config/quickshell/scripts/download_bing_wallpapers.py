#!/usr/bin/env python3
"""
Bing Wallpaper Downloader for QuickShell

This script downloads daily Bing wallpapers and saves them to Pictures/Wallpapers.
It automatically handles different resolutions and falls back to available ones if requested resolution is not available.
It also supports multiple regions to provide more variety in wallpapers.

Usage:
    python3 download_bing_wallpapers.py [resolution] [count] [regions]
    
Examples:
    python3 download_bing_wallpapers.py 1920x1080 8    # Download 8 wallpapers at 1920x1080 from auto-detected region
    python3 download_bing_wallpapers.py 2560x1440 1    # Download 1 wallpaper at 2560x1440 from auto-detected region
    python3 download_bing_wallpapers.py 3840x2160 4 "en-US,en-GB,en-CA"  # Download from multiple regions
    python3 download_bing_wallpapers.py                # Default: 1920x1080, 8 wallpapers, auto-detected region

Available resolutions:
    - 1920x1080 (Full HD)
    - 2560x1440 (2K) 
    - 3840x2160 (4K)
    - 1366x768 (HD)

Available regions (examples):
    - en-US (United States)
    - en-GB (United Kingdom)
    - en-CA (Canada)
    - en-AU (Australia)
    - de-DE (Germany)
    - fr-FR (France)
    - ja-JP (Japan)
    - zh-CN (China)
    - pt-BR (Brazil)
    - es-ES (Spain)

The script will automatically fall back to available resolutions if the requested one is not available.
"""

import json
import requests
import os
import sys
import locale
from pathlib import Path
from urllib.parse import urljoin

def detect_user_region():
    """Detect user's region based on system locale"""
    try:
        # Get system locale
        system_locale = locale.getdefaultlocale()[0]
        if system_locale:
            # Convert locale to Bing region format
            # Examples: en_US -> en-US, de_DE -> de-DE
            region = system_locale.replace('_', '-')
            return region
    except:
        pass
    
    # Fallback to US if detection fails
    return "en-US"

def get_bing_wallpapers(count=8, region="en-US"):
    """Fetch Bing wallpaper data from the API for a specific region"""
    url = f"https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n={count}&mkt={region}"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        return data.get('images', [])
    except Exception as e:
        print(f"Error fetching Bing wallpapers for region {region}: {e}")
        return []

def get_unique_wallpapers_from_regions(count=8, regions=None):
    """Get unique wallpapers from multiple regions"""
    if regions is None:
        regions = [detect_user_region()]
    
    all_wallpapers = []
    wallpapers_per_region = max(1, count // len(regions))
    
    for region in regions:
        print(f"Fetching wallpapers from region: {region}")
        region_wallpapers = get_bing_wallpapers(wallpapers_per_region, region)
        
        # Add region info to each wallpaper
        for wallpaper in region_wallpapers:
            wallpaper['region'] = region
        
        all_wallpapers.extend(region_wallpapers)
    
    # Remove duplicates based on startdate and title
    unique_wallpapers = []
    seen = set()
    
    for wallpaper in all_wallpapers:
        key = (wallpaper.get('startdate'), wallpaper.get('title'))
        if key not in seen:
            seen.add(key)
            unique_wallpapers.append(wallpaper)
    
    # Limit to requested count
    return unique_wallpapers[:count]

def download_wallpaper(image_data, resolution, output_dir):
    """Download a single wallpaper with specified resolution"""
    # Extract base URL and create full URL for the specified resolution
    url_base = image_data.get('urlbase', '')
    if not url_base:
        return False, "No URL base found"
    
    # Create filename from title and date
    title = image_data.get('title', 'bing_wallpaper')
    startdate = image_data.get('startdate', 'unknown')
    region = image_data.get('region', 'unknown')
    
    # Clean title for filename
    clean_title = "".join(c for c in title if c.isalnum() or c in (' ', '-', '_')).rstrip()
    clean_title = clean_title.replace(' ', '_')
    
    filename = f"bing_{startdate}_{clean_title}_{region}_{resolution}.jpg"
    filepath = os.path.join(output_dir, filename)
    
    # Check if file already exists
    if os.path.exists(filepath):
        return True, f"File already exists: {filename}"
    
    try:
        # Use different URL patterns based on resolution
        if resolution == "3840x2160":  # 4K
            # Try to get the UHD version from Bing first
            full_url = f"https://www.bing.com{url_base}_UHD.jpg"
            response = requests.get(full_url, timeout=30, stream=True)
            
            # If UHD is not available, try the third-party service
            if response.status_code == 404:
                # Get the original Bing URL to extract the image path
                original_url = image_data.get('url', '')
                if original_url:
                    # The third-party service uses base64 encoded URLs
                    import base64
                    # Encode the original Bing URL
                    original_bing_url = f"https://www.bing.com{original_url}"
                    encoded_url = base64.urlsafe_b64encode(original_bing_url.encode()).decode()
                    # Use the third-party service with 4K width
                    full_url = f"https://imgproxy.nanxiongnandi.com/cVAe_1mC04F_AauBgAsFPicdh_DM1WaxLJmFkfnCJIA/w:3840/q:100/att:1/{encoded_url}"
                    response = requests.get(full_url, timeout=30, stream=True)
                else:
                    # Fallback to standard resolution
                    full_url = f"https://www.bing.com{url_base}_{resolution}.jpg"
                    response = requests.get(full_url, timeout=30, stream=True)
        elif resolution == "2560x1440":  # 2K
            # Try to get the UHD version from Bing first
            full_url = f"https://www.bing.com{url_base}_UHD.jpg"
            response = requests.get(full_url, timeout=30, stream=True)
            
            # If UHD is not available, try the third-party service
            if response.status_code == 404:
                # Get the original Bing URL to extract the image path
                original_url = image_data.get('url', '')
                if original_url:
                    # The third-party service uses base64 encoded URLs
                    import base64
                    # Encode the original Bing URL
                    original_bing_url = f"https://www.bing.com{original_url}"
                    encoded_url = base64.urlsafe_b64encode(original_bing_url.encode()).decode()
                    # Use the third-party service with 2K width
                    full_url = f"https://imgproxy.nanxiongnandi.com/DFUK6qYlR6Y1gGqSbAy8e28QFBnc7YU5i8I_36ZSpYI/w:2560/q:100/att:1/{encoded_url}"
                    response = requests.get(full_url, timeout=30, stream=True)
                else:
                    # Fallback to standard resolution
                    full_url = f"https://www.bing.com{url_base}_{resolution}.jpg"
                    response = requests.get(full_url, timeout=30, stream=True)
        else:
            # Use standard Bing URLs for 1080p and 768p
            full_url = f"https://www.bing.com{url_base}_{resolution}.jpg"
            response = requests.get(full_url, timeout=30, stream=True)
        
        # If the requested resolution is not available, try to get the original URL
        if response.status_code == 404:
            original_url = image_data.get('url', '')
            if original_url:
                # Extract resolution from original URL
                import re
                match = re.search(r'_(\d+x\d+)\.jpg', original_url)
                if match:
                    original_resolution = match.group(1)
                    print(f"  Resolution {resolution} not available, trying {original_resolution}")
                    full_url = f"https://www.bing.com{url_base}_{original_resolution}.jpg"
                    response = requests.get(full_url, timeout=30, stream=True)
                    # Update filename to reflect actual resolution
                    filename = f"bing_{startdate}_{clean_title}_{region}_{original_resolution}.jpg"
                    filepath = os.path.join(output_dir, filename)
        
        response.raise_for_status()
        
        with open(filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return True, f"Downloaded: {filename}"
    except Exception as e:
        return False, f"Error downloading {filename}: {e}"

def main():
    # Available resolutions
    resolutions = {
        "1920x1080": "1920x1080",
        "2560x1440": "2560x1440", 
        "3840x2160": "3840x2160",
        "1366x768": "1366x768"
    }
    
    # Get resolution from command line argument
    resolution = "1920x1080"  # default
    if len(sys.argv) > 1:
        resolution = sys.argv[1]
    
    if resolution not in resolutions:
        print(f"Invalid resolution. Available: {', '.join(resolutions.keys())}")
        sys.exit(1)
    
    # Get count from command line argument (default 8)
    count = 8
    if len(sys.argv) > 2:
        try:
            count = int(sys.argv[2])
        except ValueError:
            count = 8
    
    # Get regions from command line argument (default auto-detect)
    regions = None
    if len(sys.argv) > 3:
        regions = sys.argv[3].split(',')
    else:
        # Auto-detect user's region
        detected_region = detect_user_region()
        print(f"Auto-detected region: {detected_region}")
        regions = [detected_region]
    
    # Create output directory
    pictures_dir = Path.home() / "Pictures" / "Wallpapers"
    pictures_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Downloading {count} Bing wallpapers at {resolution} resolution...")
    print(f"Regions: {', '.join(regions)}")
    print(f"Output directory: {pictures_dir}")
    
    # Fetch wallpaper data from multiple regions
    wallpapers = get_unique_wallpapers_from_regions(count, regions)
    if not wallpapers:
        print("Failed to fetch wallpaper data")
        sys.exit(1)
    
    print(f"Found {len(wallpapers)} unique wallpapers from {len(regions)} region(s)")
    
    # Download each wallpaper
    success_count = 0
    for i, wallpaper in enumerate(wallpapers, 1):
        region = wallpaper.get('region', 'unknown')
        print(f"[{i}/{len(wallpapers)}] Downloading: {wallpaper.get('title', 'Unknown')} (Region: {region})")
        success, message = download_wallpaper(wallpaper, resolution, pictures_dir)
        print(f"  {message}")
        if success:
            success_count += 1
    
    print(f"\nDownload complete! {success_count}/{len(wallpapers)} wallpapers downloaded successfully.")
    print(f"Files saved to: {pictures_dir}")

if __name__ == "__main__":
    main() 