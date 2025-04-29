document.addEventListener('DOMContentLoaded', () => {
  // Update copyright year
  document.getElementById('current-year').textContent = new Date().getFullYear();
  
  // Hero code tabs functionality
  const heroTabButtons = document.querySelectorAll('.code-tab');
  const heroTabPanes = document.querySelectorAll('.hero-tab-content .code-content');
  
  heroTabButtons.forEach(button => {
    button.addEventListener('click', () => {
      // Remove active class from all buttons and panes
      heroTabButtons.forEach(btn => btn.classList.remove('active'));
      heroTabPanes.forEach(pane => pane.classList.remove('active'));
      
      // Add active class to clicked button
      button.classList.add('active');
      
      // Show the corresponding tab pane
      const tabId = button.getAttribute('data-hero-tab') + '-tab';
      document.getElementById(tabId).classList.add('active');
    });
  });
  
  // Main page tab functionality
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');
  
  tabButtons.forEach(button => {
    button.addEventListener('click', () => {
      // Remove active class from all buttons and panes
      tabButtons.forEach(btn => btn.classList.remove('active'));
      tabPanes.forEach(pane => pane.classList.remove('active'));
      
      // Add active class to clicked button
      button.classList.add('active');
      
      // Show the corresponding tab pane
      const tabId = button.getAttribute('data-tab');
      document.getElementById(tabId).classList.add('active');
    });
  });
  
  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;
      
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        window.scrollTo({
          top: targetElement.offsetTop - 80, // Offset for fixed header
          behavior: 'smooth'
        });
      }
    });
  });
  
  // Load Dart language support for PrismJS
  if (typeof Prism !== 'undefined') {
    Prism.plugins.autoloader.languages_path = 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.27.0/components/';
    
    // Force highlighting for Dart code blocks
    document.querySelectorAll('code.language-dart').forEach(block => {
      if (Prism.languages.dart) {
        // If Dart language is already loaded
        Prism.highlightElement(block);
      } else {
        // Load Dart language support and highlight when ready
        const script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.27.0/components/prism-dart.min.js';
        script.onload = () => Prism.highlightElement(block);
        document.head.appendChild(script);
      }
    });
    
    // Highlight code blocks with other languages
    document.querySelectorAll('code.language-yaml, code.language-bash').forEach(block => {
      Prism.highlightElement(block);
    });
  }
});