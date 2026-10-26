::  EIP-191 vectors generated independently with eth-account 0.13.7, public test private key 1. Never fund this address.
=/  m  (strand ,vase)
=/  now  ~2026.10.26
=/  expires  (add 300 (div (sub now ~1970.1.1) ~s1))
=/  st  *state
=/  owner  0x7e5f.4552.091a.6912.5d5d.fcb7.b8c2.6590.2939.5bdf
=/  cfg=collection  ['Example' 8.453 0xabc %club %holder %dm 'Claim:' &]
=.  collections.st  (malt ~[[%example cfg]])
=.  owners.st  (malt ~[[~nec owner] [~zod owner] [~bud 0x2]])
=.  tokens.st  (malt ~[[[%example 7] owner] [[%example 8] owner]])
=.  claims.st  (malt ~[[[%example 7] [~nec owner 1]]])
=.  revision.st  1
=.  base-url.st  'https://example.test'
=.  azimuth-at.st  now
=.  nft-at.st  (malt ~[[%example now]])
=/  signature  '0x46c90e5a673d1057d1ae77618e8e9c0b70020112fead88da4922b3b13c9bc5f051e058941d5ef26bae8ffba7f214e32b0b0f2f01aeb1bd606cbf229039c7b2891c'
=/  expected-message  `@t`0x2e.6e6f.6974.6361.736e.6172.7420.726f.2072.6566.736e.6172.7420.5446.4e20.6f4e.202e.6567.6e61.6863.206e.6f69.7461.6963.6f73.7361.2073.6968.7420.796c.6e6f.2065.7a69.726f.6874.7541.0a30.3031.3337.3932.3937.3120.3a73.646e.6f63.6573.2078.696e.5520.7461.2073.6572.6970.7845.0a30.203a.6e6f.6974.6172.656e.6567.206e.656b.6f54.0a31.203a.6e6f.6973.6976.6552.0a64.6f7a.7e20.3a70.6968.7320.6f54.0a63.656e.7e20.3a70.6968.7320.6d6f.7246.0a66.6462.3539.3339.3230.3935.3632.6338.6237.6263.6664.3564.3532.3139.3661.3139.3032.3535.3466.3565.3778.3020.3a72.656e.774f.0a37.203a.6e65.6b6f.540a.656c.706d.6178.6520.3a6e.6f69.7463.656c.6c6f.430a.6362.6130.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.3030.7830.203a.7463.6172.746e.6f43.0a33.3534.3820.3a44.4920.6e69.6168.430a.7473.6574.2e65.6c70.6d61.7865.2f2f.3a73.7074.7468.203a.4c52.550a.6365.6e7e.203a.7473.6f48.0a31.7620.7265.6673.6e61.7274.206e.6f69.7461.6963.6f73.7361.2072.6574.6147
~|  %message-matches-independent-eip191-vector
=/  msg  (message:wallet st now ~zod ~nec [%example 7] 1 expires)
?>  ?=(%& -.msg)
?>  =(expected-message p.msg)
?>  =(0xb889.ee29.8c52.3722.4fcf.7633.3b07.3b3c.0c7f.ac8e.a2fe.97d9.5401.5b63.4e0a.26cc (personal-hash:wallet p.msg))
~|  %valid-wallet-authorizes-occupied-claim
=/  moved  (claim:wallet st now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%& -.moved)
?>  =(~zod who:(~(got by claims.p.moved) [%example 7]))
~|  %signature-replay-is-rejected
=/  replay  (claim:wallet p.moved now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.replay)
~|  %wrong-wallet-rejected
=/  wrong  (claim:wallet st now ~zod ~nec [%example 7] 1 expires '0x86b14d1694dfeb68a13f7dd2330ff094df13138153bc8787189a79acfaa457e808201b0c7e54ceb4a815de352e36a607476e9a3f605acd825d6bc96db564270f1b')
?>  ?=(%| -.wrong)
~|  %expired-signature-rejected
=/  expired  (claim:wallet st (add now ~m5) ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.expired)
~|  %overlong-expiry-rejected
=/  future  (claim:wallet st now ~zod ~nec [%example 7] 1 +(expires) signature)
?>  ?=(%| -.future)
~|  %wrong-host-rejected
=/  host  (claim:wallet st now ~zod ~bud [%example 7] 1 expires signature)
?>  ?=(%| -.host)
~|  %wrong-url-rejected
=/  url  (claim:wallet st(base-url 'https://elsewhere.test') now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.url)
~|  %wrong-token-rejected
=/  other  st(claims (malt ~[[[%example 8] [~nec owner 1]]]))
=/  token  (claim:wallet other now ~zod ~nec [%example 8] 1 expires signature)
?>  ?=(%| -.token)
~|  %changed-chain-rejected
=/  chain  (claim:wallet st(collections (malt ~[[%example cfg(chain 1)]])) now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.chain)
~|  %changed-generation-rejected
=/  generation  (claim:wallet st(token-generations (malt ~[[[%example 7] 9]])) now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.generation)
~|  %changed-owner-rejected
=/  sold  st(tokens (malt ~[[[%example 7] 0x2]]), owners (malt ~[[~zod 0x2]]))
=/  changed  (claim:wallet sold now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.changed)
~|  %stale-source-rejected
=/  stale  (claim:wallet st(azimuth-at ~2000.1.1) now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.stale)
~|  %suppressed-target-rejected
=/  banned  (claim:wallet st(suppressed (silt ~[[%club ~zod]])) now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.banned)
~|  %malformed-signature-rejected-without-crash
?>  =(~ (recover:wallet expected-message '0x00'))
?>  =(~ (recover:wallet expected-message '0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'))
~|  %invalid-curve-point-is-rejected-without-crash
?>  =(~ (recover:wallet expected-message '0x000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000011b'))
~|  %high-s-signature-rejected
?>  =(~ (recover:wallet expected-message '0x46c90e5a673d1057d1ae77618e8e9c0b70020112fead88da4922b3b13c9bc5f0ae1fa76be2a10d94517004580deb1cd3af9fade50096e2db53133bfc966e8eb81b'))
~|  %invalid-recovery-id-rejected
?>  =(~ (recover:wallet expected-message '0x46c90e5a673d1057d1ae77618e8e9c0b70020112fead88da4922b3b13c9bc5f051e058941d5ef26bae8ffba7f214e32b0b0f2f01aeb1bd606cbf229039c7b2891f'))
~|  %legacy-zero-one-recovery-id-supported
?>  =(`owner (recover:wallet expected-message '0x46c90e5a673d1057d1ae77618e8e9c0b70020112fead88da4922b3b13c9bc5f051e058941d5ef26bae8ffba7f214e32b0b0f2f01aeb1bd606cbf229039c7b28901'))
~|  %unauthorized-ship-cannot-transfer
=/  actor  (reassign st now ~zod ~zod [%example 7] 1)
?>  ?=(%| -.actor)
~|  %linked-ship-can-transfer-to-eligible-ship
=/  transfer  (reassign st now ~nec ~zod [%example 7] 1)
?>  ?=(%& -.transfer)
~|  %linked-ship-cannot-transfer-to-ineligible-ship
=/  ineligible  (reassign st now ~nec ~bud [%example 7] 1)
?>  ?=(%| -.ineligible)
~|  %linked-ship-cannot-displace-recipients-other-claim
=/  occupied  st(claims (~(put by claims.st) [%example 8] [~zod owner 1]))
=/  conflict  (reassign occupied now ~nec ~zod [%example 7] 1)
?>  ?=(%| -.conflict)
~|  %other-collection-does-not-block-transfer
=/  independent  st(claims (~(put by claims.st) [%other 8] [~zod owner 1]))
=/  allowed  (reassign independent now ~nec ~zod [%example 7] 1)
?>  ?=(%& -.allowed)
~|  %wallet-transfer-keeps-one-token-per-ship
=/  moved-two  (claim:wallet occupied now ~zod ~nec [%example 7] 1 expires signature)
?>  ?=(%& -.moved-two)
?>  =(1 ~(wyt by claims.p.moved-two))
~|  %wallet-proof-is-bound-to-destination-ship
=/  siblings  st(owners (~(put by owners.st) ~bud owner))
=/  destination  (claim:wallet siblings now ~bud ~nec [%example 7] 1 expires signature)
?>  ?=(%| -.destination)
(pure:m !>([%gater-wallet-tests 26 %passed]))
