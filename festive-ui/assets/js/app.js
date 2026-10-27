/* =========================================================================
   Diwali Storefront — progressive enhancement layer.
   The pages are fully rendered static HTML; everything here is optional polish.
   ========================================================================= */
(() => {
  'use strict';

  const $ = (sel, ctx = document) => ctx.querySelector(sel);
  const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ------------------------------------------------------------- toast */
  const toastEl = $('#toast');
  let toastTimer;
  function toast(message) {
    if (!toastEl) return;
    toastEl.textContent = message;
    toastEl.classList.add('is-visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('is-visible'), 2200);
  }

  /* ------------------------------------------- scroll reveal + sticky UI */
  const backTop = $('#backTop');
  const storeHead = $('#storeHead');

  function onScroll() {
    const y = window.scrollY || document.documentElement.scrollTop;
    if (backTop) backTop.classList.toggle('is-visible', y > 700);
    if (storeHead) storeHead.classList.toggle('is-stuck', y > 8);
  }
  let scrollQueued = false;
  window.addEventListener('scroll', () => {
    if (scrollQueued) return;
    scrollQueued = true;
    requestAnimationFrame(() => { onScroll(); scrollQueued = false; });
  }, { passive: true });
  onScroll();

  if (backTop) {
    backTop.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
    });
  }

  if ('IntersectionObserver' in window && !reduceMotion) {
    const io = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-in');
          obs.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -6% 0px', threshold: 0.04 });
    $$('.reveal').forEach(el => io.observe(el));
  } else {
    $$('.reveal').forEach(el => el.classList.add('is-in'));
  }

  /* -------------------------------------------------------------- rails */
  $$('.rail').forEach(rail => {
    const prev = $('.rail-nav--prev', rail);
    const next = $('.rail-nav--next', rail);
    const step = () => Math.max(rail.clientWidth * 0.72, 220);

    prev && prev.addEventListener('click', () =>
      rail.scrollBy({ left: -step(), behavior: reduceMotion ? 'auto' : 'smooth' }));
    next && next.addEventListener('click', () =>
      rail.scrollBy({ left: step(), behavior: reduceMotion ? 'auto' : 'smooth' }));

    rail.addEventListener('keydown', ev => {
      if (ev.key === 'ArrowRight' || ev.key === 'ArrowLeft') {
        ev.preventDefault();
        rail.scrollBy({ left: ev.key === 'ArrowRight' ? step() : -step(), behavior: 'smooth' });
      }
    });

    const updateNav = () => {
      const max = Math.max(0, rail.scrollWidth - rail.clientWidth);
      rail.classList.toggle('has-overflow', max > 4);
      if (prev) prev.disabled = rail.scrollLeft <= 2;
      if (next) next.disabled = rail.scrollLeft >= max - 2;
    };
    rail.addEventListener('scroll', updateNav, { passive: true });
    window.addEventListener('resize', updateNav, { passive: true });
    requestAnimationFrame(updateNav);

    // Pointer drag-to-scroll (desktop / trackpad-friendly).
    let startX = 0, startScroll = 0, dragging = false, moved = false;
    rail.addEventListener('pointerdown', ev => {
      if (ev.pointerType === 'touch' || ev.button !== 0 || ev.target.closest('button, a')) return;
      dragging = true; moved = false;
      startX = ev.clientX; startScroll = rail.scrollLeft;
      rail.classList.add('is-dragging');
    });
    rail.addEventListener('pointermove', ev => {
      if (!dragging) return;
      const delta = ev.clientX - startX;
      if (Math.abs(delta) > 4) moved = true;
      rail.scrollLeft = startScroll - delta;
    });
    const endDrag = () => {
      if (!dragging) return;
      dragging = false;
      rail.classList.remove('is-dragging');
    };
    rail.addEventListener('pointerup', endDrag);
    rail.addEventListener('pointerleave', endDrag);
    rail.addEventListener('pointercancel', endDrag);
    rail.addEventListener('click', ev => { if (moved) { ev.preventDefault(); ev.stopPropagation(); } }, true);
  });

  /* ------------------------------------------------------- cart / steppers */
  const cartBar = $('#cartBar');
  const cartCount = $('#cartCount');
  const cartPrice = $('#cartPrice');

  function numericPrice(str) {
    const n = parseInt(String(str).replace(/[^\d]/g, ''), 10);
    return Number.isFinite(n) ? n : 0;
  }

  function refreshCart() {
    let qty = 0, total = 0;
    $$('.product.is-added').forEach(card => {
      const count = parseInt($('.product__count', card).textContent, 10) || 1;
      const price = numericPrice(card.dataset.price || $('.product__price', card).textContent);
      qty += count;
      total += count * price;
    });
    if (cartCount) cartCount.textContent = `${qty} item${qty === 1 ? '' : 's'}`;
    if (cartPrice) cartPrice.textContent = `₹${total.toLocaleString('en-IN')}`;
    if (cartBar) cartBar.classList.toggle('is-visible', qty > 0);
  }

  $$('.product').forEach(card => {
    const add = $('.product__add', card);
    const countEl = $('.product__count', card);

    add && add.addEventListener('click', () => {
      card.classList.add('is-added');
      refreshCart();
    });

    $$('[data-step]', card).forEach(btn => {
      btn.addEventListener('click', () => {
        let n = parseInt(countEl.textContent, 10) || 1;
        n += Number(btn.dataset.step);
        if (n <= 0) {
          card.classList.remove('is-added');
          countEl.textContent = '1';
        } else {
          countEl.textContent = String(n);
        }
        refreshCart();
      });
    });

    const wish = $('.product__wish', card);
    wish && wish.addEventListener('click', () => {
      const on = wish.classList.toggle('is-on');
      wish.setAttribute('aria-pressed', String(on));
      toast(on ? 'Saved to your wishlist' : 'Removed from wishlist');
    });

    const similar = $('.product__similar', card);
    similar && similar.addEventListener('click', () => toast('Showing more like this soon'));
  });

  if (cartBar) {
    cartBar.addEventListener('click', () => toast('Your festive cart is looking good!'));
  }

  /* -------------------------------------------------------- live search */
  const noResults = document.createElement('p');
  noResults.className = 'no-results';
  noResults.textContent = 'No festive finds matched that search. Try “diya”, “candle” or “gift”.';
  const main = $('main');
  if (main) main.prepend(noResults);

  const searchInputs = $$('input[type="search"]');
  let searchTimer;
  function runSearch(term) {
    const q = term.trim().toLowerCase();
    let visible = 0;
    $$('.product').forEach(card => {
      const name = card.dataset.name || '';
      const match = !q || name.includes(q);
      card.hidden = !match;
      if (match) visible++;
    });
    // Collapse sections whose carousels have no matching products.
    $$('.section--plain').forEach(zone => {
      const has = $$('.product:not([hidden])', zone).length > 0;
      zone.style.display = has ? '' : 'none';
      const head = zone.previousElementSibling;
      if (head && head.classList.contains('section')) head.style.display = has ? '' : 'none';
    });
    noResults.classList.toggle('is-visible', q.length > 0 && visible === 0);
    if (q.length > 0 && !reduceMotion) {
      $$('.section.reveal').forEach(el => el.classList.add('is-in'));
    }
  }
  searchInputs.forEach(input => {
    input.addEventListener('input', () => {
      clearTimeout(searchTimer);
      searchTimer = setTimeout(() => runSearch(input.value), 140);
    });
    input.form && input.form.addEventListener('submit', ev => ev.preventDefault());
  });

  /* -------------------------------------------------------- voice search */
  $$('.voice').forEach(btn => {
    btn.addEventListener('click', () => {
      const on = btn.classList.toggle('is-listening');
      btn.setAttribute('aria-pressed', String(on));
      toast(on ? 'Listening… say a product name' : 'Voice search stopped');
      if (on) setTimeout(() => {
        btn.classList.remove('is-listening');
        btn.setAttribute('aria-pressed', 'false');
      }, 3600);
    });
  });

  /* ------------------------------------------------------- tabs / chips */
  $$('.tab[data-tab]').forEach(tab => {
    tab.addEventListener('click', ev => {
      if (tab.getAttribute('href') === '#') {
        ev.preventDefault();
        $$('.tab').forEach(t => t.classList.remove('is-active'));
        tab.classList.add('is-active');
        toast(`Browsing ${$('span', tab).textContent} — coming soon`);
      }
    });
  });

  $$('.chip-tile').forEach(chip => {
    chip.addEventListener('click', () => {
      $$('.chip-tile').forEach(c => c.classList.remove('is-active'));
      chip.classList.add('is-active');
      toast($('span:last-child', chip).textContent.replace(/\s+/g, ' ').trim());
    });
  });

  $$('.nav-item[href="#"], .nav-zomato[href="#footer"]').forEach(link => {
    link.addEventListener('click', ev => {
      if (link.getAttribute('href') === '#') {
        ev.preventDefault();
        toast($('span', link) ? $('span', link).textContent : 'Coming soon');
      }
    });
  });

  /* ------------------------------------------------- gentle entrance cue */
  if (!reduceMotion) {
    document.body.animate(
      [{ opacity: 0.6 }, { opacity: 1 }],
      { duration: 320, easing: 'ease-out' }
    );
  }
})();
