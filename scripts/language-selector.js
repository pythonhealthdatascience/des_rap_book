<script>

function setLanguage(lang) {
  // Store the selected language in localStorage
  localStorage.setItem('preferredLanguage', lang);

  // Update button active state
  document.querySelectorAll('.language-button').forEach(btn => {
      btn.classList.remove('active');
      if (btn.textContent.toLowerCase() === lang || (lang === 'both' && btn.textContent.toLowerCase() === 'both')) {
          btn.classList.add('active');
      }
  });
  // Show/hide the appropriate content
  if (lang === 'python') {
      document.querySelectorAll('.python-content').forEach(el => el.style.display = 'block');
      document.querySelectorAll('.r-content').forEach(el => el.style.display = 'none');
  } else if (lang === 'r') {
      document.querySelectorAll('.python-content').forEach(el => el.style.display = 'none');
      document.querySelectorAll('.r-content').forEach(el => el.style.display = 'block');
  }
}

// On page load, set the language based on localStorage or default to Python
document.addEventListener('DOMContentLoaded', function() {
  const lang = localStorage.getItem('preferredLanguage') || 'python';
  setLanguage(lang);
});

</script>