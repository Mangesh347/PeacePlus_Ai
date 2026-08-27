import requests
from bs4 import BeautifulSoup
import csv
import random
import time
import os

# Sample function to clean data
def clean_text(text):
    text = text.replace("\xa0", " ").strip()
    return text

# Function to simulate scraping user queries from a forum or social media
def scrape_forgiveness_queries(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Assuming queries are in <div> tags with a specific class, adjust based on actual structure
    queries = soup.find_all('div', class_='query-text')
    cleaned_queries = [clean_text(query.text) for query in queries]
    
    return cleaned_queries

# Simulate extraction of user data
def generate_user_data(query):
    # Randomly generating user data
    user_id = random.randint(1000, 9999)
    gender = random.choice(['Male', 'Female', 'Other'])
    age_group = random.choice(['18-25', '26-35', '36-45', '46-60', '60+'])
    emotional_tone = random.choice(['Positive', 'Negative', 'Neutral'])
    platform = "Quora"  # Example platform
    category = random.choice(['Self-forgiveness', 'Relationship Forgiveness', 'Moral Dilemma', 'Forgiving Others'])
    
    # Generate a random date within a year range
    date_posted = f"2025-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
    
    return {
        'User ID': user_id,
        'Forgiveness Query': query,
        'Date': date_posted,
        'Location': 'USA',  # You could scrape location from user's IP or profile if available
        'Gender': gender,
        'Age Group': age_group,
        'Emotional Tone': emotional_tone,
        'Platform': platform,
        'Topic Category': category,
        'User Behavior': random.choice(['Active', 'Inactive'])
    }

# Function to save data to CSV
def save_to_csv(data, filename='forgiveness_queries.csv'):
    file_exists = os.path.isfile(filename)
    
    with open(filename, mode='a', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        
        if not file_exists:
            writer.writeheader()
        
        for entry in data:
            writer.writerow(entry)

# Function to scrape data continuously
def scrape_continuous_data(urls, total_queries=1000):
    all_data = []
    query_count = 0
    
    while query_count < total_queries:
        print(f"Scraping query number {query_count + 1}...")  # Print statement for progress
        url = random.choice(urls)  # Randomly select a URL to scrape
        queries = scrape_forgiveness_queries(url)
        
        for query in queries:
            if query_count >= total_queries:
                break
            user_data = generate_user_data(query)
            all_data.append(user_data)
            query_count += 1
        
        # Delay between requests to avoid getting blocked
        time.sleep(random.uniform(1, 3))
    
    print("Data scraping complete. Saving to CSV...")  # Inform when scraping is done
    save_to_csv(all_data)

# List of URLs to scrape (e.g., Quora, Reddit, etc.)
urls = [
    'https://www.quora.com/topic/Forgiveness',
    'https://www.reddit.com/r/relationships/',
    'https://www.reddit.com/r/selfimprovement/',
]

# Scraping 1000 unique queries
print("Starting the scraping process...")  # Initial message indicating the start
scrape_continuous_data(urls, 1000)
