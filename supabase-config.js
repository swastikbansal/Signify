// Supabase storage helper injected before content.js
// Reads config from chrome.storage.sync (keys: supabaseUrl, supabaseAnonKey, bucketName='animations')
// Provides: init(), isConfigured(), getObjectURL(fileName), getSignedURL(fileName), fetchAvailableModels()

(function(){
	const DEFAULT_BUCKET = 'animations';
	const STATE = {
		supabaseUrl: 'https://qqyqwtoxjhgashwxyidg.supabase.co/',
		supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxeXF3dG94amhnYXNod3h5aWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MjE5NjIsImV4cCI6MjA2OTE5Nzk2Mn0.IOB5ocrqZPKU6luezwhmLGXUkKgks9w0AM7X2-onI-c',
		bucket: 'animations',
		useSigned: false,
		initialized: false,
		cache: new Map(), // fileName -> url
		listingCache: null,
		lastListTime: 0
	};

	async function loadSettings(){
		return new Promise(resolve => {
			chrome.storage.sync.get([
				'supabaseUrl','supabaseAnonKey','bucketName','useSigned'
			], items => resolve(items||{}));
		});
	}

	async function init(){
		if (STATE.initialized) return true;
		try {
			const cfg = await loadSettings();
			STATE.supabaseUrl = (cfg.supabaseUrl||'').replace(/\/$/,'');
			STATE.supabaseAnonKey = cfg.supabaseAnonKey||null;
			STATE.bucket = cfg.bucketName || DEFAULT_BUCKET;
			STATE.useSigned = cfg.useSigned === true; // default false
			if (STATE.supabaseUrl && STATE.supabaseAnonKey){
				STATE.initialized = true;
				console.log('[SupabaseConfig] Initialized with bucket', STATE.bucket, 'signed=', STATE.useSigned);
			} else {
				console.warn('[SupabaseConfig] Missing supabaseUrl or anon key in storage');
			}
		} catch(e){
			console.error('[SupabaseConfig] init error', e);
		}
		return STATE.initialized;
	}

	function isConfigured(){
		return !!(STATE.initialized && STATE.supabaseUrl && STATE.supabaseAnonKey);
	}

	function buildPublicURL(fileName){
		if (!isConfigured()) return null;
		const encoded = encodeURIComponent(fileName);
		return `${STATE.supabaseUrl}/storage/v1/object/public/${STATE.bucket}/${encoded}`;
	}

	async function getSignedURL(fileName){
		if (!isConfigured()) return null;
		try {
			const res = await fetch(`${STATE.supabaseUrl}/storage/v1/object/sign/${STATE.bucket}/${encodeURIComponent(fileName)}`, {
				method:'POST',
				headers:{
					'apikey': STATE.supabaseAnonKey,
					'Authorization': `Bearer ${STATE.supabaseAnonKey}`,
					'Content-Type':'application/json'
				},
				body: JSON.stringify({ expiresIn: 3600 })
			});
			if(!res.ok){
				return null;
			}
			const data = await res.json();
			if (data?.signedURL){
				// Prepend supabaseUrl if not absolute
				if (/^https?:/i.test(data.signedURL)) return data.signedURL;
				return `${STATE.supabaseUrl}${data.signedURL}`;
			}
		} catch(e){
			console.warn('[SupabaseConfig] signed URL error', fileName, e);
		}
		return null;
	}

	async function getObjectURL(fileName){
		if (!isConfigured()) return null;
		if (STATE.cache.has(fileName)) return STATE.cache.get(fileName);
		let url = buildPublicURL(fileName);
		if (STATE.useSigned){
			const signed = await getSignedURL(fileName);
			if (signed) url = signed;
		}
		// Probe existence quickly (HEAD)
		try {
			const controller = new AbortController();
			const t = setTimeout(()=>controller.abort(), 5000);
			const resp = await fetch(url, { method:'HEAD', signal: controller.signal });
			clearTimeout(t);
			if (!resp.ok){
				return null;
			}
		} catch(e){
			return null;
		}
		STATE.cache.set(fileName, url);
		return url;
	}

	async function fetchAvailableModels(force=false){
		if (!isConfigured()) return [];
		const now = Date.now();
		if (!force && STATE.listingCache && (now-STATE.lastListTime)<60000){
			return STATE.listingCache;
		}
		try {
			const listUrl = `${STATE.supabaseUrl}/storage/v1/object/list/${STATE.bucket}`;
			const res = await fetch(listUrl, {
				method:'POST',
				headers:{
					'apikey': STATE.supabaseAnonKey,
					'Authorization': `Bearer ${STATE.supabaseAnonKey}`,
					'Content-Type':'application/json'
				},
				body: JSON.stringify({ prefix: '', limit: 1000 })
			});
			if(!res.ok){
				console.warn('[SupabaseConfig] list failed status', res.status);
				return [];
			}
			const data = await res.json();
			const models = (Array.isArray(data)?data:[])
				.filter(it => /\.glb$/i.test(it.name))
				.map(it => ({ name: it.name, path: buildPublicURL(it.name) }));
			STATE.listingCache = models;
			STATE.lastListTime = now;
			console.log('[SupabaseConfig] Listed', models.length, 'models');
			return models;
		} catch(e){
			console.warn('[SupabaseConfig] list error', e);
			return [];
		}
	}

	window.SupabaseStorage = { init, isConfigured, getObjectURL, getSignedURL, fetchAvailableModels };
})();

