'use strict';
document.documentElement.classList.add('js');
// Preserve native-app account entry and bookmarks into the existing web demo.
if (['/','/index.html'].includes(location.pathname) && (new URLSearchParams(location.search).get('source') === 'ios-app' || ['#chorePlanner','#questGenerator','#questGeneratorTitle','#worldMap','#communityHub'].includes(location.hash))) {
  location.replace('/demo.html' + location.search + location.hash);
}
const toggle = document.querySelector('.menu-toggle');
const nav = document.querySelector('#navigation');
toggle?.addEventListener('click', () => {
  const open = toggle.getAttribute('aria-expanded') !== 'true';
  toggle.setAttribute('aria-expanded', String(open)); nav.classList.toggle('open', open);
});
nav?.addEventListener('click', event => {
  if (event.target.closest('a')) { nav.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false'); }
});
document.querySelectorAll('[data-signup]').forEach(form => {
  let busy = false;
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (busy || !form.reportValidity()) return;
    const status = form.querySelector('.form-status');
    const button = form.querySelector('[type=submit]');
    busy = true; button.disabled = true; status.classList.remove('error'); status.textContent = 'Sending your request…';
    try {
      const response = await fetch('/', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(new FormData(form)).toString()});
      if (!response.ok) throw new Error('Submission failed');
      location.assign(form.getAttribute('action'));
    } catch {
      status.classList.add('error'); status.textContent = 'We couldn’t send your request. Your details are still here. Please try again when you have a connection.';
      button.disabled = false; busy = false;
    }
  });
});
const filters = document.querySelectorAll('[data-grade]');
filters.forEach(button => button.addEventListener('click', () => {
  filters.forEach(item => item.setAttribute('aria-pressed', String(item === button)));
  let count = 0;
  document.querySelectorAll('[data-lesson-grade]').forEach(card => {
    card.hidden = button.dataset.grade !== 'all' && card.dataset.lessonGrade !== button.dataset.grade;
    if (!card.hidden) count++;
  });
  document.querySelector('#lesson-count').textContent = `${count} free lessons shown`;
}));
