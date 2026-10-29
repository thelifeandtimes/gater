::  SVG source served as an image, never inserted as executable markup.
|_  source=@t
++  grow
  |%
  ++  mime  [~['image' 'svg+xml'] (as-octs:mimes:html source)]
  --
++  grab
  |%
  ++  mime  |=([p=mite q=octs] (@t q.q))
  ++  noun  @t
  --
++  grad  %mime
--
