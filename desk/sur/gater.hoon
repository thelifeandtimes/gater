|%
+$  asset  [collection=@tas token=@ud]
+$  collection
  $:  name=@t
      chain=@ud
      contract=@ux
      group=@tas
      role=@tas
      recognition=$~(%dm ?(%dm %invite %none))
      message=@t
      kick=$~(& ?)
  ==
+$  claim  [who=ship owner=@ux revision=@ud]
+$  seat  [group=@tas who=ship]
+$  operation
  $:  kind=?(%dm %invite %admit %revoke %kick)
      =seat
      roles=(set @tas)
      text=@t
  ==
+$  effect  [=operation status=?(%pending %sent %failed) attempts=@ud]
+$  source  [healthy=? method=@tas epoch=@ux start=@ud supply=@ud code-hash=@ux]
+$  state-0
  $:  %0
      collections=(map @tas collection)
      owners=(map ship @ux)
      tokens=(map asset @ux)
      claims=(map asset claim)
      recognized=(set [collection=@tas who=ship])
      suppressed=(set seat)
      managed=(set seat)
      applied=(map seat (set @tas))
      effects=(map @ud effect)
      revision=@ud
      serial=@ud
      azimuth-at=@da
      nft-at=(map @tas @da)
      checkpoints=(map @tas [height=@ud hash=@ux])
      ttl=$~(~m15 @dr)
      base-url=@t
      live=$~(| ?)
      fixtures=$~(| ?)
      azimuth-auto=$~(| ?)
      wake=@da
  ==
+$  state
  $:  %1
      collections=(map @tas collection)
      owners=(map ship @ux)
      tokens=(map asset @ux)
      claims=(map asset claim)
      recognized=(set [collection=@tas who=ship])
      suppressed=(set seat)
      managed=(set seat)
      applied=(map seat (set @tas))
      effects=(map @ud effect)
      revision=@ud
      serial=@ud
      azimuth-at=@da
      nft-at=(map @tas @da)
      checkpoints=(map @tas [height=@ud hash=@ux])
      ttl=$~(~m15 @dr)
      base-url=@t
      live=$~(| ?)
      fixtures=$~(| ?)
      azimuth-auto=$~(| ?)
      wake=@da
      token-generations=(map asset @ud)
      nft-sources=(map @tas source)
      azimuth-watch=$~(| ?)
      azimuth-status=$~(%off ?(%off %connecting %observed %gap))
  ==
--
