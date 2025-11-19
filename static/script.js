// Optional small UX helpers; left intentionally minimal for the DBMS demo.
(function(){
  // Highlight disabled buttons on load
  document.querySelectorAll('button[disabled]').forEach(btn => {
    btn.title = 'Out of stock';
  });
})();