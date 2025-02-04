import "phoenix_html"
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

    this.scene = new THREE.Scene();


    this.centroid = new THREE.Vector3(0, 0, 0);
    this.cameraOffset = new THREE.Vector3(0, 0, 500);
    this.camera = new THREE.PerspectiveCamera(
      75,
      canvas.clientWidth / canvas.clientHeight,
      0.1,
      1000
    );
    this.camera.position.z = 500;

    // const light = new THREE.PointLight(0xffffff, 1);
    // light.position.set(0, 0, 500);
    // this.scene.add(light);

    this.sphereMeshes = {};
    this.traces = {};

    // Track mouse for rotation
    this.isRotating = false;
    this.lastMouseX = 0;
    this.lastMouseY = 0;
    this.rotationAngleX = 0;
    this.rotationAngleY = 0;

    canvas.addEventListener("mousedown", (event) => this.onMouseDown(event));
    canvas.addEventListener("mouseup", (event) => this.onMouseUp(event));
    canvas.addEventListener("mousemove", (event) => this.onMouseMove(event));

    // Read initial simulation state from the data attribute.
    const bodies = JSON.parse(this.el.dataset.simulation);

    bodies.forEach(body => {
      const geometry = new THREE.SphereGeometry(15, 6, 4);
      // const material = new THREE.MeshPhongMaterial({ color: body.color });
      const material = new THREE.MeshBasicMaterial({ color: body.color });
      const sphere = new THREE.Mesh(geometry, material);
      // Adjust?
      sphere.position.set(body.pos[0], body.pos[1], body.pos[2]);
      this.scene.add(sphere);

      // Add espheres and traces
      this.sphereMeshes[body.id] = sphere;
      this.traces[body.id] = {
        positions: [],
        line: new THREE.Line(
          new THREE.BufferGeometry(),
          new THREE.LineBasicMaterial({ color: body.color })
        )
      };
      this.scene.add(this.traces[body.id].line);
    });

    this.animate();
  },
    // When the LiveView updates the simulation state, update the sphere positions and set listeners.
  updated() {
    this.updateSimultationData();
    this.addButtonListeners();
  },
  addButtonListeners() {
    document.querySelectorAll(".focus-button").forEach(button => {
      button.addEventListener("click", () => {
        let bodyId = button.dataset.bodyId;
        this.focusOnBody(parseInt(bodyId));
      });
    });
  },
  updateSimultationData() {
    const bodies = JSON.parse(this.el.dataset.simulation);
    if (!bodies || bodies.length === 0) {
      console.warn("No simulation data available");
      return;
    }

    let totalX = 0, totalY = 0, totalZ = 0, count = 0;
    let maxDistance = 0;

    bodies.forEach(body => {
      if (this.sphereMeshes[body.id]) {
        this.sphereMeshes[body.id].position.set(
          body.pos[0],
          body.pos[1],
          body.pos[2]
        );

        // Store past positions for tracing
        this.traces[body.id].positions.push(new THREE.Vector3(body.pos[0], body.pos[1], body.pos[2]));

        // Limit the last N positions to limit memory usage
        // if (this.traces[body.id].positions.length > 200) {
        //   this.traces[body.id].positions.shift();
        // }

        // Update the trace line
        let traceGeometry = new THREE.BufferGeometry().setFromPoints(this.traces[body.id].positions);
        this.traces[body.id].line.geometry.dispose(); // Remove old geometry
        this.traces[body.id].line.geometry = traceGeometry;

        // Calcular centro de massa para manter a câmera centralizada
        // Determinar o maior afastamento para ajustar o zoom
        let distanceFactor = 2;
        totalX += body.pos[0];
        totalY += body.pos[1];
        totalZ += body.pos[2];
        count++;
        let distanceFromCenter = Math.sqrt(body.pos[0] ** distanceFactor + body.pos[1] ** distanceFactor + body.pos[2] ** distanceFactor);
        if (distanceFromCenter > maxDistance) {
          maxDistance = distanceFromCenter;
        }
      }
    });

    // Atualizar a posição da câmera para seguir o centro de massa
    if (count > 0) {
      // Atualiza apenas o centro da massa, mas não a posição da câmera diretamente
      this.centroid.set(totalX / count, totalY / count, totalZ / count);
    }
  },
  animate() {
    requestAnimationFrame(() => this.animate(), 128);

    if (this.isRotating) {
      let radius = this.camera.position.distanceTo(this.centroid);

      let angleX = this.rotationAngleX * (Math.PI / 180);
      let angleY = this.rotationAngleY * (Math.PI / 180);

      // Compute new camera position around centroid
      this.camera.position.x = this.centroid.x + radius * Math.cos(angleX) * Math.cos(angleY);
      this.camera.position.y = this.centroid.y + radius * Math.sin(angleY);
      this.camera.position.z = this.centroid.z + radius * Math.sin(angleX) * Math.cos(angleY);

      this.camera.lookAt(this.centroid);
    }

    this.renderer.render(this.scene, this.camera);
  },
  onMouseDown(event) {
    if (event.button === 0) { // LMB
        this.isRotating = true;
        this.lastMouseX = event.clientX;
        this.lastMouseY = event.clientY;
    }
  },

  onMouseUp(event) {
      if (event.button === 0) { // LMB
          this.isRotating = false;
      }
  },

  onMouseMove(event) {
    if (this.isRotating) {
      let deltaX = event.clientX - this.lastMouseX;
      let deltaY = event.clientY - this.lastMouseY;

      this.rotationAngleX += deltaX * 0.2;
      this.rotationAngleY += deltaY * 0.2;

      this.lastMouseX = event.clientX;
      this.lastMouseY = event.clientY;
    }
  },
  focusOnBody(bodyId) {
    if (!this.sphereMeshes[bodyId]) return;
  
    const targetPosition = this.sphereMeshes[bodyId].position;
  
    // Calculate the new camera position to focus on the object
    const offset = new THREE.Vector3(0, 0, 150);
    const newCameraPosition = targetPosition.clone().add(offset);
  
    const duration = 1000; // (in milliseconds)
    const startTime = performance.now();
    const startCameraPosition = this.camera.position.clone();
  
    const animateTransition = (currentTime) => {
      const elapsed = currentTime - startTime;
      const interpolationFactor = 1; // (0 to 1)
      const t = Math.min(elapsed / duration, interpolationFactor);
  
      this.camera.position.lerpVectors(startCameraPosition, newCameraPosition, t);
      this.camera.lookAt(targetPosition);
  
      if (t < 1) {
        requestAnimationFrame(animateTransition);
      }
    };
  
    requestAnimationFrame(animateTransition);
  }
  
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  // longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket
