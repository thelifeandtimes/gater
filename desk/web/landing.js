'use strict';
// Preserve only the collection hint; login never accepts a caller's redirect URL.
const collection = new URLSearchParams(location.search).get('collection');
if (collection && /^[a-z][a-z0-9-]*$/.test(collection)) {
  const target = `/gater/claim?${new URLSearchParams({collection})}`;
  document.getElementById('return-to').value = target;
  document.getElementById('continue').href = target;
}
