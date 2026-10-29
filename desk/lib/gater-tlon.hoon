::  Wire adapter pinned to tlon-apps e599fab / group-action-5 / chat-dm-action-2.
::  The observation mold preserves unused noun fields, avoiding a second copy
::  of Tlon's complete type graph. Only the versioned v3 group scry is accepted.
/-  *gater
|%
+$  group-view
  $:  meta=*
      blob=*
      admissions=[privacy=@tas banned=[ships=(set ship) ranks=(set @tas)] pending=(map ship (set @tas)) requests=* tokens=* referrals=* invited=*]
      seats=(map ship [roles=(set @tas) joined=@da])
      roles=(map @tas *)
      admins=(set @tas)
      channels=(map [kind=@tas host=ship name=@tas] *)
      active=*
      sections=*
      order=*
      flagged=*
  ==
+$  observation
  $:  member=?
      pending=?
      roles=(set @tas)
      banned=?
      protected=?
      available=(set @tas)
      admins=(set @tas)
  ==
++  observe
  |=  [group=group-view who=ship host=ship]
  ^-  observation
  =/  member  (~(get by seats.group) who)
  =/  pending  (~(get by pending.admissions.group) who)
  =/  roles  ?~(member ?~(pending *(set @tas) u.pending) roles.u.member)
  =/  protected=?
    ?|  =(host who)
        !=(~ (~(int in roles) admins.group))
        (lien ~(tap by channels.group) |=([[kind=@tas owner=ship name=@tas] val=*] =(owner who)))
    ==
  :*  ?=(^ member)
      ?=(^ pending)
      roles
      |((~(has in ships.banned.admissions.group) who) (~(has in ranks.banned.admissions.group) (clan:title who)))
      protected
      ~(key by roles.group)
      admins.group
  ==
++  allowed
  |=  [op=operation ob=observation]
  ^-  ?
  ?&  !protected.ob
      |(?=(?(%revoke %kick) kind.op) !banned.ob)
      =(~ (~(dif in roles.op) available.ob))
      =(~ (~(int in roles.op) admins.ob))
  ==
++  observed
  |=  [op=operation ob=observation]
  ^-  ?
  ?-  kind.op
    %dm      |
    %invite  |(member.ob pending.ob)
    %admit   &(member.ob =(~ (~(dif in roles.op) roles.ob)))
    %revoke  =(~ (~(int in roles.op) roles.ob))
    %kick    &(!member.ob !pending.ob)
  ==
++  command
  |=  [op=operation ob=observation host=ship message-at=@da]
  ^-  [agent=@tas cage]
  =/  ships  (silt ~[who.seat.op])
  ?:  ?=(%dm kind.op)
    :-  %chat
    :-  %chat-dm-action-2
    !>  :*  who.seat.op
            [host message-at]
            %add
            [[~[[%inline ~[text.op]]] host message-at] [%chat ~] ~ ~]
            ~
        ==
  :-  %groups
  :-  %group-action-5
  =/  flag  [host group.seat.op]
  ?-  kind.op
    %invite  !>([%group flag %entry %pending ships %add *(set @tas)])
    %admit   ?:  member.ob
               !>([%group flag %seat ships %add-roles roles.op])
             !>([%group flag %entry %pending ships %add (~(uni in roles.ob) roles.op)])
    %revoke  ?:  member.ob
               !>([%group flag %seat ships %del-roles roles.op])
             !>([%group flag %entry %pending ships %edit (~(dif in roles.ob) roles.op)])
    %kick    ?:  member.ob
               !>([%group flag %seat ships %del ~])
             !>([%group flag %entry %pending ships %del ~])
  ==
--
