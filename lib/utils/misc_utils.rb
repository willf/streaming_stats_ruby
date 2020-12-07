# from https://stackoverflow.com/questions/6892551/array-prototype-splice-in-ruby
# Same as Javascript splice, but not put on Array prototype
def splice!(a, start, len, *replacements)
    r = a.slice!(start, len)
    a[start, 0] = replacements if(replacements)
    r
  end
