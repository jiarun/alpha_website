// ===== SHARED JS - Alpha Ry =====

function updateLangUrl(lang) {
  const url = new URL(window.location.href);
  if (lang === 'fi') {
    url.searchParams.set('lang', 'fi');
  } else {
    url.searchParams.delete('lang');
  }
  window.history.replaceState({}, '', url);

  const canonical = document.querySelector('link[rel="canonical"]');
  if (canonical) canonical.href = url.href;
  const ogUrl = document.querySelector('meta[property="og:url"]');
  if (ogUrl) ogUrl.content = url.href;
}

// Language Switcher
function setLang(lang) {
  document.querySelectorAll('[data-en]').forEach(el => {
    el.textContent = el.getAttribute('data-' + lang);
  });
  document.querySelectorAll('[data-en-placeholder]').forEach(el => {
    el.placeholder = el.getAttribute('data-' + lang + '-placeholder');
  });
  document.querySelectorAll('.lang-btn').forEach(btn => btn.classList.remove('active'));
  const btn = document.querySelector(`.lang-btn[onclick="setLang('${lang}')"]`);
  if (btn) btn.classList.add('active');
  document.documentElement.lang = lang;
  localStorage.setItem('alphary-lang', lang);
  updateLangUrl(lang);
}

// Restore saved language on page load
document.addEventListener('DOMContentLoaded', () => {
  const params = new URLSearchParams(window.location.search);
  const urlLang = params.get('lang');
  const saved = localStorage.getItem('alphary-lang');
  const initialLang = urlLang === 'fi' ? 'fi' : saved;
  if (initialLang && initialLang !== 'en') setLang(initialLang);

  // Dynamic footer year
  document.querySelectorAll('.footer-year').forEach(el => {
    el.textContent = new Date().getFullYear();
  });
});

// Hamburger Menu
function initHamburger() {
  const hamburger = document.querySelector('.hamburger');
  const mobileNav = document.querySelector('.mobile-nav');
  if (!hamburger || !mobileNav) return;

  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    mobileNav.classList.toggle('open');
    const isOpen = mobileNav.classList.contains('open');
    document.body.style.overflow = isOpen ? 'hidden' : '';
    hamburger.setAttribute('aria-expanded', isOpen);
    mobileNav.setAttribute('aria-hidden', !isOpen);
  });

  mobileNav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      hamburger.classList.remove('active');
      mobileNav.classList.remove('open');
      document.body.style.overflow = '';
      hamburger.setAttribute('aria-expanded', 'false');
      mobileNav.setAttribute('aria-hidden', 'true');
    });
  });
}
document.addEventListener('DOMContentLoaded', initHamburger);

// Smooth Scroll
document.addEventListener('click', e => {
  const anchor = e.target.closest('a[href^="#"]');
  if (!anchor) return;
  e.preventDefault();
  const target = document.querySelector(anchor.getAttribute('href'));
  if (target) target.scrollIntoView({ behavior: 'smooth' });
});

// Lightbox with accessibility
function openLightbox(src) {
  const lb = document.getElementById('lightbox');
  const img = document.getElementById('lightbox-img');
  if (!lb || !img) return;
  img.src = src;
  img.alt = 'Enlarged photo';
  lb.classList.add('open');
  lb.setAttribute('aria-hidden', 'false');
  lb.setAttribute('role', 'dialog');
  lb.setAttribute('aria-label', 'Image lightbox');
  document.body.style.overflow = 'hidden';
  // Focus close button
  const closeBtn = document.getElementById('lightbox-close');
  if (closeBtn) closeBtn.focus();
}

function closeLightbox() {
  const lb = document.getElementById('lightbox');
  if (!lb) return;
  lb.classList.remove('open');
  lb.setAttribute('aria-hidden', 'true');
  document.body.style.overflow = '';
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    closeLightbox();
    closeCampOverlay();
  }
});

// Camp popup (used on cricket page)
function closeCampOverlay() {
  const overlay = document.getElementById('camp-overlay');
  if (!overlay) return;
  overlay.classList.remove('open');
  overlay.setAttribute('aria-hidden', 'true');
  sessionStorage.setItem('cricketCampSeen', '1');
}

function initCampPopup(delay) {
  if (sessionStorage.getItem('cricketCampSeen')) return;
  setTimeout(() => {
    const overlay = document.getElementById('camp-overlay');
    if (overlay) {
      overlay.classList.add('open');
      overlay.setAttribute('aria-hidden', 'false');
    }
  }, delay || 2000);
}

// Form Submit
function handleSubmit(e) {
  e.preventDefault();
  const lang = localStorage.getItem('alphary-lang') || 'en';
  const msg = lang === 'fi' ? 'Kiitos! Otamme sinuun yhteyttä pian.' : 'Thank you! We will get back to you soon.';
  alert(msg);
  e.target.reset();
}
