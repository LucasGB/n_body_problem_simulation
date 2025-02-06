import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import * as THREE from "../vendor/three.min.js";
// import * as THREE from "three";
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
const AU_SCALE = 20*20;

let Hooks = {};
Hooks.ThreeDHook = {
  mounted() {
    const canvas = this.el.querySelector("#three-canvas");
    if (!canvas) {
      console.error("Canvas element not found!");
      return;
    }
    this.renderer = new THREE.WebGLRenderer({ canvas });
    this.renderer.setSize(canvas.clientWidth, canvas.clientHeight);

    this.scene = new THREE.Scene();

    this.centroid = new THREE.Vector3(0, 0, 0);
    this.camera = new THREE.PerspectiveCamera(
      75,
      canvas.clientWidth / canvas.clientHeight,
      0.1,
      1000000
    );
    this.camera.position.set(0, 0, 50);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.enablePan = true;
    this.controls.enableRotate = true;
    this.controls.enableZoom = true;
    this.controls.dampingFactor = 0.05;
    this.controls.screenSpacePanning = false;
    this.controls.minDistance = 50;
    this.controls.maxDistance = 20000;
    this.controls.coupleCenters = false;
    this.controls.keys = {
      LEFT: 'KeyA',
      RIGHT: 'KeyD',
      UP: 'KeyW',
      BOTTOM: 'KeyS'
    }
    this.controls.keyPanSpeed = 20;
    this.controls.listenToKeyEvents(window);

    this.userInteracting = false;
    this.autoAdjustTimeout = null;

    this.controls.addEventListener('start', () => {
      this.userInteracting = true;
      if (this.autoAdjustTimeout) clearTimeout(this.autoAdjustTimeout);
    });
    this.controls.addEventListener('end', () => {
      if (this.autoAdjustTimeout) clearTimeout(this.autoAdjustTimeout);
      this.autoAdjustTimeout = setTimeout(() => {
        this.userInteracting = false;
      }, 2000);
    });

    this.sphereMeshes = {};
    this.traces = {};

    const bodies = JSON.parse(this.el.dataset.simulation);
    this.g = new THREE.Group();
    this.scene.add(this.g);
    bodies.forEach(body => {
      const geometry = new THREE.SphereGeometry(body.radius, 6, 4);
      // const material = new THREE.MeshPhongMaterial({ color: body.color });
      const material = new THREE.MeshBasicMaterial({ color: body.color });
      const sphere = new THREE.Mesh(geometry, material);
      sphere.position.set(
        body.pos[0] * AU_SCALE,
        body.pos[1] * AU_SCALE,
        body.pos[2] * AU_SCALE
      );
      this.g.add(sphere);

      // Armazena as referências das esferas e suas trilhas
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
    this.addGridHelper();
    this.animate();
  },

  addGridHelper() {
    this.gridHelper = new THREE.GridHelper(4000, 40, 0x0000ff, 0x808080);
    this.gridHelper.position.y = 0;
    this.gridHelper.position.x = 0;
    this.scene.add(this.gridHelper);

    let bbox = new THREE.Box3().setFromObject(this.g);
    let helper = new THREE.Box3Helper(bbox, new THREE.Color(0, 255, 0));
    // this.scene.add(helper);

    let center = new THREE.Vector3();
    bbox.getCenter(center);

    let bsphere = bbox.getBoundingSphere(new THREE.Sphere(center));
    let m = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      opacity: 0.3,
      transparent: true
    });
    var geometry = new THREE.SphereGeometry(bsphere.radius, 32, 32);
    let sMesh = new THREE.Mesh(geometry, m);
    this.scene.add(sMesh);
    sMesh.position.copy(center);
  },

  showGridLines() {
    this.gridHelper.visible = !this.gridHelper.visible;
  },

  updated() {
    this.updateSimultationData();
    this.addButtonListeners();
  },

  addButtonListeners() {
    document.querySelectorAll("#adjust-button").forEach(button => {
      button.addEventListener("click", () => {
        this.adjustCameraZoom();
      });
    });

    document.querySelectorAll("#show-grid-lines").forEach(button => {
      button.addEventListener("click", () => {
        this.showGridLines();
      });
    });

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

    bodies.forEach(body => {
      if (this.sphereMeshes[body.id]) {
        let pos = new THREE.Vector3(
          body.pos[0] * AU_SCALE,
          body.pos[1] * AU_SCALE,
          body.pos[2] * AU_SCALE
        );
        this.sphereMeshes[body.id].position.copy(pos);
        
        this.traces[body.id].positions.push(pos);
        // Limit the last N positions to limit memory usage
        // if (this.traces[body.id].positions.length > 200) {
        //   this.traces[body.id].positions.shift();
        // }

        let traceGeometry = new THREE.BufferGeometry().setFromPoints(this.traces[body.id].positions);
        this.traces[body.id].line.geometry.dispose();
        this.traces[body.id].line.geometry = traceGeometry;

      }
    });
  },

  adjustCameraZoom() {
    let bbox = new THREE.Box3().setFromObject(this.g);
    const center = new THREE.Vector3();
    bbox.getCenter(center);
    this.centroid.copy(center);
    this.controls.target.copy(this.centroid);
    let bsphere = bbox.getBoundingSphere(new THREE.Sphere(center));

    let zoomFactor = 2.0; 
    let newCameraDistance = bsphere.radius * zoomFactor;
    newCameraDistance = Math.max(newCameraDistance, 50);

    let duration = 500; // Tempo da transição em ms
    let startTime = performance.now();
    let startCameraPosition = this.camera.position.clone();
    let targetCameraPosition = this.centroid.clone().add(new THREE.Vector3(0, 0, newCameraDistance));

    const animateZoom = (currentTime) => {
      let elapsed = currentTime - startTime;
      let t = Math.min(elapsed / duration, 1); // Normaliza para [0, 1]

      this.camera.position.lerpVectors(startCameraPosition, targetCameraPosition, t);

      if (t < 1) {
        requestAnimationFrame(animateZoom);
      }
    };

    requestAnimationFrame(animateZoom);
  },

  animate() {
    requestAnimationFrame(this.animate.bind(this));
    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  },

  focusOnBody(bodyId) {
    if (!this.sphereMeshes[bodyId]) return;
  
    const targetPosition = this.sphereMeshes[bodyId].position;
  
    const offset = new THREE.Vector3(0, 0, 150);
    const newCameraPosition = targetPosition.clone().add(offset);
  
    const duration = 1000; // em ms
    const startTime = performance.now();
    const startCameraPosition = this.camera.position.clone();
  
    const animateTransition = (currentTime) => {
      const elapsed = currentTime - startTime;
      const t = Math.min(elapsed / duration, 1);
  
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
