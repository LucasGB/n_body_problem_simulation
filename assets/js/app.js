// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import * as THREE from "../vendor/three.min.js";
// import * as THREE from "three";

console.log("app.js loaded");

let Hooks = {};

Hooks.ThreeDHook = {
  mounted() {
    console.log("ThreeDHook mounted", this.el);
    // Initialize three.js using the canvas element.
    const canvas = this.el.querySelector("#three-canvas");
    if (!canvas) {
      console.error("Canvas element not found!");
      return;
    }
    this.renderer = new THREE.WebGLRenderer({ canvas });
    this.renderer.setSize(canvas.clientWidth, canvas.clientHeight);

    // Create a scene and a camera.
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(
      75,
      canvas.clientWidth / canvas.clientHeight,
      0.1,
      1000
    );
    // Position the camera so that the scene is visible.
    this.camera.position.z = 500;

    // Add a light to the scene.
    const light = new THREE.PointLight(0xffffff, 1);
    light.position.set(0, 0, 500);
    this.scene.add(light);

    // Create a dictionary to hold our sphere meshes.
    this.sphereMeshes = {};

    // Read initial simulation state from the data attribute.
    const bodies = JSON.parse(this.el.dataset.simulation);
    bodies.forEach(body => {
      const geometry = new THREE.SphereGeometry(5, 32, 32);
      const material = new THREE.MeshPhongMaterial({ color: 0x0077ff });
      const sphere = new THREE.Mesh(geometry, material);
      // Adjust coordinates as needed (here we center around 0,0,0)
      sphere.position.set(body.pos[0] - 250, body.pos[1] - 250, body.pos[2] - 250);
      this.scene.add(sphere);
      this.sphereMeshes[body.id] = sphere;
    });

    // Start the animation loop.
    this.animate();
  },
  updated() {
    // When the LiveView updates the simulation state, update the sphere positions.
    const bodies = JSON.parse(this.el.dataset.simulation);
    bodies.forEach(body => {
      if (this.sphereMeshes[body.id]) {
        this.sphereMeshes[body.id].position.set(
          body.pos[0] - 250,
          body.pos[1] - 250,
          body.pos[2] - 250
        );
      }
    });
  },
  animate() {
    requestAnimationFrame(() => this.animate());
    this.renderer.render(this.scene, this.camera);
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  // longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

