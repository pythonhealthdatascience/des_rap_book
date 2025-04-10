function setLanguage(lang) {
    // Store the selected language in localStorage
    localStorage.setItem('preferredLanguage', lang);
    
    // Show/hide the appropriate content
    if (lang === 'python') {
      document.querySelectorAll('.python-content').forEach(el => el.style.display = 'block');
      document.querySelectorAll('.r-content').forEach(el => el.style.display = 'none');
    } else {
      document.querySelectorAll('.python-content').forEach(el => el.style.display = 'none');
      document.querySelectorAll('.r-content').forEach(el => el.style.display = 'block');
    }
  }
  
  // On page load, set the language based on localStorage or default to Python
  document.addEventListener('DOMContentLoaded', function() {
    const lang = localStorage.getItem('preferredLanguage') || 'python';
    setLanguage(lang);
  });
  