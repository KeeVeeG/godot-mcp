/* ═══════════════════════════════════════════════════════════
   PARTICLES
   ═══════════════════════════════════════════════════════════ */
(function initParticles() {
  const container = document.getElementById('particles');
  if (!container) return;
  const count = 25;
  for (let i = 0; i < count; i++) {
    const p = document.createElement('div');
    p.className = 'particle';
    p.style.left = Math.random() * 100 + '%';
    p.style.animationDelay = Math.random() * 8 + 's';
    p.style.animationDuration = 6 + Math.random() * 6 + 's';
    p.style.width = p.style.height = 2 + Math.random() * 3 + 'px';
    p.style.opacity = 0.2 + Math.random() * 0.4;
    container.appendChild(p);
  }
})();

/* ═══════════════════════════════════════════════════════════
   SCROLL REVEAL
   ═══════════════════════════════════════════════════════════ */
(function initReveal() {
  const els = document.querySelectorAll('.reveal');
  if (!els.length) return;
  const observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' },
  );
  els.forEach(function (el) {
    observer.observe(el);
  });
})();

/* ═══════════════════════════════════════════════════════════
   STAT COUNTER ANIMATION
   ═══════════════════════════════════════════════════════════ */
(function initCounters() {
  const counters = document.querySelectorAll('.stat-number[data-target]');
  if (!counters.length) return;

  const observer = new IntersectionObserver(
    function (entries) {
      const visibleCounters = [];
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        const el = entry.target;
        const target = parseInt(el.dataset.target, 10);
        const suffix = el.dataset.suffix || '';
        const staticVal = el.dataset.static;

        if (staticVal) {
          observer.unobserve(el);
          return;
        }

        visibleCounters.push({ el: el, target: target, suffix: suffix });
        observer.unobserve(el);
      });

      if (visibleCounters.length === 0) return;

      // All counters start and end at the same time
      const duration = 1500;
      const startTime = performance.now();

      function updateCounters(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);

        // Ease out cubic for smooth deceleration
        const eased = 1 - Math.pow(1 - progress, 3);

        visibleCounters.forEach(function (counter) {
          const current = Math.floor(eased * counter.target);
          counter.el.textContent = current + counter.suffix;
        });

        if (progress < 1) {
          requestAnimationFrame(updateCounters);
        } else {
          // Ensure final values are exact
          visibleCounters.forEach(function (counter) {
            counter.el.textContent = counter.target + counter.suffix;
          });
        }
      }

      requestAnimationFrame(updateCounters);
    },
    { threshold: 0.5 },
  );

  counters.forEach(function (c) {
    observer.observe(c);
  });
})();

/* ═══════════════════════════════════════════════════════════
   COPY CODE
   ═══════════════════════════════════════════════════════════ */
function copyCode() {
  const code = '{\n  "mcpServers": {\n    "godot": {\n      "command": "npx",\n      "args": ["-y", "--registry=https://npm.pkg.github.com", "@keeveeg/godot-mcp"]\n    }\n  }\n}';
  const btn = document.getElementById('copyBtn');
  navigator.clipboard
    .writeText(code)
    .then(function () {
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(function () {
        btn.textContent = 'Copy';
        btn.classList.remove('copied');
      }, 2000);
    })
    .catch(function () {
      /* Fallback for older browsers */
      const ta = document.createElement('textarea');
      ta.value = code;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(function () {
        btn.textContent = 'Copy';
        btn.classList.remove('copied');
      }, 2000);
    });
}

/* ═══════════════════════════════════════════════════════════
   MOBILE NAV TOGGLE
   ═══════════════════════════════════════════════════════════ */
(function initMobileNav() {
  const toggle = document.getElementById('navToggle');
  const links = document.getElementById('navLinks');
  if (!toggle || !links) return;
  toggle.addEventListener('click', function () {
    const isOpen = links.classList.toggle('open');
    toggle.setAttribute('aria-expanded', isOpen);
  });
  /* Close on link click */
  links.querySelectorAll('a').forEach(function (a) {
    a.addEventListener('click', function () {
      links.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    });
  });
})();

/* ═══════════════════════════════════════════════════════════
   NAV SCROLL EFFECT
   ═══════════════════════════════════════════════════════════ */
(function initNavScroll() {
  const nav = document.querySelector('nav');
  if (!nav) return;
  let ticking = false;
  window.addEventListener('scroll', function () {
    if (!ticking) {
      requestAnimationFrame(function () {
        if (window.scrollY > 50) {
          nav.style.background = 'rgba(10, 14, 23, 0.95)';
        } else {
          nav.style.background = 'rgba(10, 14, 23, 0.8)';
        }
        ticking = false;
      });
      ticking = true;
    }
  });
})();
