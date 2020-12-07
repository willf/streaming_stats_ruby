# frozen_string_literal: true

# from https://stackoverflow.com/questions/6892551/array-prototype-splice-in-ruby
# Same as Javascript splice, but not put on Array prototype
def splice!(array, start, len, *replacements)
  r = array.slice!(start, len)
  array[start, 0] = replacements if replacements
  r
end
