// Rooster Service Worker for Push Notifications and Static Asset Caching
//
// IMPORTANT: This is the ONLY service worker for the app. The Flutter build
// must use --pwa-strategy none to prevent Flutter from generating its own
// flutter_service_worker.js, which would replace this one and break push
// notifications (no push/notificationclick handlers in Flutter's SW).

const CACHE_NAME = 'rooster-v3';

// Assets to precache on install
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/flutter_bootstrap.js',
  '/icons/Icon-192.png',
];

// Install event - precache essential assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_URLS);
    })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch event - caching strategies by request type
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Network-only for API calls - never cache
  if (url.pathname.startsWith('/api/')) {
    return;
  }

  // Navigation requests (HTML pages) - network-first with cache fallback
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          return response;
        })
        .catch(() => caches.match(event.request) || caches.match('/index.html'))
    );
    return;
  }

  // Static assets (JS, WASM, CSS, fonts, images) - cache-first with network fallback
  if (isStaticAsset(url.pathname)) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        if (cached) {
          return cached;
        }
        return fetch(event.request).then((response) => {
          // Only cache successful responses
          if (response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return response;
        });
      })
    );
    return;
  }
});

function isStaticAsset(pathname) {
  return /\.(js|wasm|css|woff2?|ttf|eot|png|jpe?g|gif|ico|svg|webp)$/.test(pathname);
}

// Push event - handle incoming push notifications
self.addEventListener('push', (event) => {
  console.log('[SW] Push received');

  let data = {
    title: 'Rooster',
    body: 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    url: '/'
  };

  if (event.data) {
    try {
      const payload = event.data.json();
      data = {
        title: payload.title || data.title,
        body: payload.body || data.body,
        icon: payload.icon || data.icon,
        badge: data.badge,
        url: payload.url || data.url,
        tag: payload.tag || null,
      };
    } catch (e) {
      console.error('[SW] Error parsing push data:', e);
      data.body = event.data.text();
    }
  }

  const options = {
    body: data.body,
    icon: data.icon,
    badge: data.badge,
    vibrate: [100, 50, 100],
    data: {
      url: data.url,
    },
    requireInteraction: true,
  };

  if (data.tag) {
    options.tag = data.tag;
  }

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click event - open the app to the relevant page
self.addEventListener('notificationclick', (event) => {
  const notificationData = event.notification.data || {};
  const urlToOpen = notificationData.url || '/';

  console.log('[SW] Notification clicked, opening:', urlToOpen);
  event.notification.close();

  event.waitUntil(openApp(urlToOpen));
});

// Open or focus the app window
function openApp(url) {
  return clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
    // Check if there's already a window open
    for (const client of clientList) {
      if (client.url.includes(self.registration.scope) && 'focus' in client) {
        // Navigate the existing window to the notification URL
        client.postMessage({
          type: 'NAVIGATE',
          url: url
        });
        return client.focus();
      }
    }
    // If no window is open, open a new one
    if (clients.openWindow) {
      return clients.openWindow(url);
    }
  });
}

// Notification close event
self.addEventListener('notificationclose', (event) => {
  console.log('[SW] Notification closed by user');
});

// Handle messages from the main app
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
