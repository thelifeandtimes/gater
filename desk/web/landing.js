'use strict';
const selected = GaterCommunity.selected();
if (selected) {
  const target = `/gater/${encodeURIComponent(selected)}/claim`;
  document.getElementById('return-to').value = target;
}
GaterCommunity.load().catch((error) => {
  document.getElementById('notice').textContent = error.message;
  document.querySelector('#login button').disabled = true;
});
