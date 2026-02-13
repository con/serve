// Site-level override of Congo's mermaid.js
// Adds svg-pan-zoom integration after mermaid renders diagrams.

function css(name) {
  return "rgb(" + getComputedStyle(document.documentElement).getPropertyValue(name) + ")";
}

let isDark = document.documentElement.classList.contains("dark");

mermaid.initialize({
  theme: "base",
  themeVariables: {
    background: css("--color-neutral"),
    primaryTextColor: isDark ? css("--color-neutral-200") : css("--color-neutral-700"),
    primaryColor: isDark ? css("--color-primary-700") : css("--color-primary-200"),
    secondaryColor: isDark ? css("--color-secondary-700") : css("--color-secondary-200"),
    tertiaryColor: isDark ? css("--color-neutral-700") : css("--color-neutral-100"),
    primaryBorderColor: isDark ? css("--color-primary-500") : css("--color-primary-400"),
    secondaryBorderColor: css("--color-secondary-400"),
    tertiaryBorderColor: isDark ? css("--color-neutral-300") : css("--color-neutral-400"),
    lineColor: isDark ? css("--color-neutral-300") : css("--color-neutral-600"),
    fontFamily:
      "ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,segoe ui,Roboto,helvetica neue,Arial,noto sans,sans-serif",
    fontSize: "16px",
    pieTitleTextSize: "19px",
    pieSectionTextSize: "16px",
    pieLegendTextSize: "16px",
    pieStrokeWidth: "1px",
    pieOuterStrokeWidth: "0.5px",
    pieStrokeColor: isDark ? css("--color-neutral-300") : css("--color-neutral-400"),
    pieOpacity: "1",
  },
});

// After mermaid initializes and renders SVGs, apply svg-pan-zoom.
// Mermaid renders asynchronously, so we use a MutationObserver to detect
// when SVG elements appear inside .mermaid containers.
(function () {
  var containers = document.querySelectorAll(".mermaid");
  if (!containers.length) return;

  function applySvgPanZoom(svg) {
    // Skip if already processed
    if (svg.dataset.panZoomApplied) return;
    svg.dataset.panZoomApplied = "true";

    // Remove mermaid's inline max-width constraint so the SVG can fill the container
    svg.style.maxWidth = "none";
    svg.removeAttribute("width");

    // Ensure the SVG has width/height for svg-pan-zoom to work with
    svg.style.width = "100%";
    svg.style.height = "100%";

    svgPanZoom(svg, {
      zoomEnabled: true,
      controlIconsEnabled: true,
      fit: true,
      center: true,
      minZoom: 0.5,
      maxZoom: 10,
      zoomScaleSensitivity: 0.3,
    });
  }

  // Observe each .mermaid container for child SVG additions
  var observer = new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) {
      mutation.addedNodes.forEach(function (node) {
        if (node.nodeName && node.nodeName.toLowerCase() === "svg") {
          // Small delay to let mermaid finish any post-render adjustments
          setTimeout(function () {
            applySvgPanZoom(node);
          }, 100);
        }
      });
    });
  });

  containers.forEach(function (container) {
    // Check if SVG is already rendered (in case observer attaches late)
    var existingSvg = container.querySelector("svg");
    if (existingSvg) {
      setTimeout(function () {
        applySvgPanZoom(existingSvg);
      }, 100);
    }

    // Watch for future SVG insertions
    observer.observe(container, { childList: true });
  });
})();
