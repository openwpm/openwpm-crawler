from .crawl_utils import get_sampled_sites

location = "/tmp/"
sampled_sites = get_sampled_sites(location)
n = len(sampled_sites)

print ("%s sampled sites stored in %ssampled_sites.json" % (n, location))
