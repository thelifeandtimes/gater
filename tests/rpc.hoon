::  Native RPC trust boundaries and resumable transitions, with no network.
=/  m  (strand ,vase)
=/  now  ~2026.10.29
=/  fails
  |=  gate=(trap)
  =/  caught  (mule gate)
  ?=(%| -.caught)
=/  rejected  |=(r=* ?=([%| *] r))
=/  accepted  |=(r=* ?=([%& *] r))
=/  obj  pairs:enjs:format
=/  s  *store
=.  s  s(errors (~(put by errors.s) %azimuth 'Old provider error'))
~|  %credentials-are-write-only-and-empty-fields-preserve
=/  configured  (configure s (obj ~['infuraKey'^s+'test-key']) now)
?>  ?=(%& -.configured)
=.  s  p.configured
?>  =(~ errors.s)
?>  =('https://mainnet.infura.io/v3/test-key' (endpoint s 1))
?>  =('https://base-mainnet.infura.io/v3/test-key' (endpoint s 8.453))
?>  =('' (str:j (status-json s) 'infuraKey'))
?>  (bool:j (status-json s) 'infuraConfigured' |)
=/  kept  (configure s (obj ~['infuraKey'^s+'']) now)
?>  ?=(%& -.kept)
?>  =(infura.s infura.p.kept)
~|  %custom-overrides-and-explicit-clear
=/  custom  (configure s (obj ~['ethereumUrl'^s+'https://provider.example/private']) now)
?>  ?=(%& -.custom)
?>  =('https://provider.example/private' (endpoint p.custom 1))
=/  cleared  (configure p.custom (obj ~['clearEthereum'^b+& 'clearInfura'^b+&]) now)
?>  ?=(%& -.cleared)
?>  =('' (endpoint p.cleared 1))
~|  %reject-insecure-endpoints-and-header-injection
?>  (rejected (configure s (obj ~['baseUrl'^s+'http://provider.example']) now))
?>  !(safe-url (cat 3 'https://provider.example' 10))
?>  (rejected (configure s (obj ~['infuraKey'^s+'key/path']) now))
~|  %reviewed-event-coverage-required
?>  (rejected (parse-options (obj ~[mode+s+'events-supply']) [%enumerable 0 '']))
?>  (accepted (parse-options (obj ~[mode+s+'events-supply' start+s+'100' review+s+'Reviewed all mint paths']) [%enumerable 0 '']))
~|  %batch-matches-id-independent-of-response-order
=/  calls=(list call)  ~[['eth_chainId' ~] ['eth_blockNumber' ~]]
=/  row0  (obj ~[jsonrpc+s+'2.0' id+s+'9:0' result+s+'0x1'])
=/  row1  (obj ~[jsonrpc+s+'2.0' id+s+'9:1' result+s+'0x2'])
?>  =(~[s+'0x1' s+'0x2'] (results calls 9 a+~[row1 row0]))
~|  %batch-rejects-missing-duplicate-wrong-id-and-errors
?>  (fails |.((results calls 9 a+~[row0])))
?>  (fails |.((results calls 9 a+~[row0 row0])))
?>  (fails |.((results calls 10 a+~[row0 row1])))
=/  bad  (obj ~[jsonrpc+s+'2.0' id+s+'9:1' error+s+'provider error'])
?>  (fails |.((results calls 9 a+~[row0 bad])))
~|  %fresh-finalized-headers-required
=/  h  (obj ~[number+s+'0x64' hash+s+(word 0xabc) timestamp+s+(number-hex (div (sub now ~1970.1.1) ~s1))])
?>  (fresh-header (parse-header h) now)
?>  !(fresh-header (parse-header h) (sub now ~s1))
?>  !(fresh-header (parse-header h) (add now ~h2))
=/  w  *job
=.  w  w(kind %nft, chain 1, col %test, contract 0x123, stage %chain, opts [%enumerable 0 ''], epoch 0x1, requests ~[['eth_chainId' ~]])
~|  %wrong-chain-rejected
?>  (fails |.((advance w ~[s+'0x2105'] now)))
~|  %enumerable-bootstrap-pins-every-call-to-finalized-block
=.  w  (advance w ~[s+'0x1'] now)
?>  =(%head stage.w)
=.  w  (advance w ~[h] now)
?>  =(%code stage.w)
=.  w  (advance w ~[s+'0x6000'] now)
?>  =(%supply stage.w)
=.  w  (advance w ~[s+'0x1' s+'0x2'] now)
?>  =(%enumerable stage.w)
=.  w  (advance w ~[s+'0x1'] now)
?>  =(%enumerate stage.w)
?>  =(2 (lent requests.w))
~|  %duplicate-token-ids-rejected
?>  (fails |.((advance w ~[s+'0x7' s+'0x7'] now)))
=.  w  (advance w ~[s+'0x7' s+'0x9'] now)
?>  =(%owners stage.w)
~|  %zero-owner-rejected
?>  (fails |.((advance w ~[s+'0x0' s+'0x456'] now)))
=.  w  (advance w ~[s+'0x123' s+'0x456'] now)
?>  =(%finish stage.w)
~|  %checkpoint-rechecked-before-atomic-commit
=/  fork  (obj ~[number+s+'0x64' hash+s+(word 0xdef) timestamp+(get:j h 'timestamp')])
?>  (fails |.((advance w ~[fork] now)))
=.  w  (advance w ~[h] now)
?>  =(%done stage.w)
?>  =(2 ~(wyt by tokens.w))
?>  (lien (array:j (get:j (snapshot-json w now) 'tokens')) |=(row=json =('7' (str:j row 'id'))))
~|  %resumable-job-roundtrips-without-secrets-in-public-status
=/  restored  !<(job !>(w))
?>  =(w restored)
~|  %transfer-away-and-back-invalidates-claim-generation
=/  original  (~(got by tokens.w) 7)
=/  e=event:audit  [mined=`[~ 0 0 0xaaa 101 0xbbb |] address=0x123 data='0x' topics=~[transfer 0x123 0x456 0x7]]
=.  w  (apply-transfer w e)
?>  =(0x456 owner:(~(got by tokens.w) 7))
=.  w  (apply-transfer w e(topics ~[transfer 0x456 0x123 0x7], mined `[~ 1 0 0xaaa 101 0xbbb |]))
?>  =(owner.original owner:(~(got by tokens.w) 7))
?>  !=(generation.original generation:(~(got by tokens.w) 7))
~|  %missing-transfer-history-rejected
?>  (fails |.((apply-transfer w e(topics ~[transfer 0x999 0x456 0x7]))))
~|  %burn-deletes-token
=.  w  (apply-transfer w e(topics ~[transfer 0x123 0x0 0x7]))
?>  !(~(has by tokens.w) 7)
~|  %duplicate-mint-rejected
?>  (fails |.((apply-transfer w e(topics ~[transfer 0x0 0x123 0x9]))))
~|  %erc2309-mint-range-and-bounds
=.  w  (apply-transfer w e(topics ~[consecutive 0x14 0x0 0x123], data '0x16'))
?>  (levy ^-((list @ud) ~[20 21 22]) |=(id=@ud (~(has by tokens.w) id)))
?>  (fails |.((apply-transfer w e(topics ~[consecutive 0x1e 0x0 0x123], data '0x1b'))))
~|  %checkpoint-regression-rejected
=.  w  w(stage %head, previous [101 0xdef now], requests ~[(block-call 'finalized')])
?>  (fails |.((advance w ~[h] now)))
::  Exercise full log parsing and canonical block / rollup input binding.
=/  log-json
  |=  [address=@ux first=@ux after=@ux id=@ux]
  (pairs:enjs:format ~[address+s+(addr:j address) data+s+'0x' topics+a+~[s+(word transfer) s+(word first) s+(word after) s+(word id)] 'blockNumber'^s+'0x32' 'blockHash'^s+(word 0xdef) 'logIndex'^s+(number-hex id) 'transactionIndex'^s+'0x0' 'transactionHash'^s+(word 0xaaa) removed+b+|])
=/  event1  (log-json 0x123 0x0 0x123 0x7)
=/  event2  (log-json 0x123 0x0 0x456 0x9)
=/  block50  (obj ~[number+s+'0x32' hash+s+(word 0xdef) timestamp+(get:j h 'timestamp')])
=/  w=job  *job
=.  w  w(kind %nft, col %test, chain 1, contract 0x123, opts [%events-supply 10 'Reviewed'], bootstrap 10, target (parse-header h), supply 2, epoch 0x1, cursor 10)
=.  w  (log-request w)
~|  %foreign-removed-out-of-range-and-duplicate-logs-rejected
?>  (fails |.((advance w ~[a+~[(log-json 0x999 0x0 0x123 0x7)]] now)))
?>  (fails |.((advance w ~[a+~[event1 event1]] now)))
?>  ?=([%o *] event1)
=/  removed  (obj (weld ~[removed+b+&] (skim ~(tap by p.event1) |=([key=@t val=json] !=(key 'removed')))))
?>  (fails |.((advance w ~[a+~[removed]] now)))
?>  (fails |.((advance w(cursor 60) ~[a+~[event1]] now)))
~|  %logs-are-sorted-and-checked-against-canonical-blocks
=.  w  (advance w ~[a+~[event2 event1]] now)
?>  =(%blocks stage.w)
?>  =([100 0xabc now] target.w)
?>  (fails |.((advance w ~[h] now)))
=.  w  (advance w ~[block50] now)
?>  =(%owners stage.w)
=.  w  (advance w ~[s+'0x123' s+'0x456'] now)
=.  w  (advance w ~[h] now)
?>  =(%done stage.w)
~|  %transfer-history-must-reconcile-to-supply
=/  w=job  w(stage %logs, requests ~[['eth_getLogs' ~]], tokens ~, changed ~, cursor 10, last 100, supply 3)
=.  w  (advance w ~[a+~[event1 event2]] now)
?>  (fails |.((advance w ~[block50] now)))
~|  %rollup-transaction-is-bound-to-hash-block-and-destination
=/  w=job  *job
=.  w  w(kind %azimuth, chain 1, cursor 10, target (parse-header h))
=.  w  (log-request w)
=.  w  (advance w ~[a+~[(log-json rollup-address 0x0 0x123 0x7)]] now)
=.  w  (advance w ~[block50] now)
?>  =(%inputs stage.w)
=/  tx  (obj ~[hash+s+(word 0xaaa) 'blockHash'^s+(word 0xdef) 'blockNumber'^s+'0x32' to+s+(addr:j rollup-address) input+s+'0x123456'])
?>  ?=([%o *] tx)
=/  bad-tx  (obj (weld ~[to+s+(addr:j 0x123)] (skim ~(tap by p.tx) |=([key=@t val=json] !=(key 'to')))))
?>  (fails |.((advance w ~[bad-tx] now)))
=.  w  (advance w ~[tx] now)
?>  =(%finish stage.w)
?>  =(`0x12.3456 input:(need mined:(snag 0 logs.w)))
=.  w  (advance w ~[h] now)
?>  =(%done stage.w)
~|  %provider-errors-never-return-remote-text
=/  remote-error  (obj ~[error+(obj ~[code+n+'-32005' message+s+'secret provider URL and API key'])])
?>  =(`'RPC provider rate or query limit reached. Retrying with bounded backoff.' (provider-error a+~[remote-error]))
~|  %migration-keeps-credentials-checkpoints-and-pending-work
=/  old=store-0  *store-0
=.  old  old(infura 'private-key', work `w, serial 99)
=/  migrated  (migrate-store old)
?>  =('private-key' infura.migrated)
?>  =(`w work.migrated)
?>  =(99 serial.migrated)
?>  =(~ bootstrap.migrated)

~|  %code-fingerprint-matches-released-worker
?>  =(0xcf4f.d7ee.a44b.785d.e574.3869.26af.7efe.1ef8.813e.a900.2dad.7d36.3b7c.d918.2d71 (code-hash s+'0x6000'))
~|  %long-bootstrap-retains-verified-prefix-and-catches-up-before-commit
=/  w=job  w(stage %finish, requests ~[(block-call '0x64')])
=/  caught  (advance w ~[h] (add now ~h2))
?>  =(%head stage.caught)
?>  =(target.w previous.caught)
?>  =(101 cursor.caught)
?>  =(logs.w logs.caught)
?>  =(tokens.w tokens.caught)
~|  %released-checkpoint-migration-requires-matching-reviewed-coverage
=/  st=state  *state
=/  col=collection  ['Example' 1 0x123 %example %holder %none '' &]
=.  st  st(collections (~(put by collections.st) %test col), checkpoints (~(put by checkpoints.st) %test [100 0xabc]), nft-sources (~(put by nft-sources.st) %test [& %events-supply 0x1 10 1 0xabc]), tokens (~(put by tokens.st) [%test 7] 0x123), token-generations (~(put by token-generations.st) [%test 7] 99))
=/  saved=store  *store
?>  (fails |.((start saved st `%test now)))
=.  saved  saved(indexes (~(put by indexes.saved) %test [%events-supply 11 'Reviewed']))
?>  (fails |.((start saved st `%test now)))
=.  saved  saved(indexes (~(put by indexes.saved) %test [%events-supply 10 'Reviewed']))
=/  migrated  (start saved st `%test now)
?>  =(0x1 epoch.migrated)
?>  =(101 cursor.migrated)
?>  =([0x123 99] (~(got by tokens.migrated) 7))
?>  (~(has in changed.migrated) 7)
(pure:m !>([%gater-rpc-tests 29 %passed]))
