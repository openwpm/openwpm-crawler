import redis


sites = ['1,http://www.example.com',
         '2,http://www.princeton.edu',
         '3,http://citp.princeton.edu/']

r = redis.Redis(host='localhost', port=31000, db=0)

for site in sites:
    print("Adding " + site + " to the crawl queue")
    r.rpush('crawl-queue', site)
