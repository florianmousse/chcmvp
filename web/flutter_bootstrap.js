{{flutter_js}}
{{flutter_build_config}}

const bootTimeout = setTimeout(() => {
  const status = document.getElementById('loading-status');
  if (status) status.textContent = 'Le chargement prend plus de temps que prévu. Vérifie ta connexion, puis recharge la page.';
}, 30000);

_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' },
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine({ canvasKitBaseUrl: 'canvaskit/' });
      await appRunner.runApp();
      clearTimeout(bootTimeout);
      document.getElementById('loading')?.remove();
    } catch (error) {
      clearTimeout(bootTimeout);
      document.getElementById('loading-status').textContent = "Impossible de démarrer l'application. Recharge la page ou essaie un navigateur récent.";
      console.error('Démarrage CHC MVP impossible', error);
    }
  }
});
