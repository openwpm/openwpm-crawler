import redis


sites = ['http://www.example.com',
         'http://www.princeton.edu',
         'http://citp.princeton.edu/']

r = redis.Redis(host='localhost', port=31000, db=0)

for site in sites:
    print("Adding " + site + " to the crawl queue")
    r.rpush('crawl-queue', site)
