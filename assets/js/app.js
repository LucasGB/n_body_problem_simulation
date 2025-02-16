import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import * as THREE from "../vendor/three.min.js";
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const AU_SCALE = 10;

let Hooks = {};
Hooks.ThreeDHook = {
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
  
  mounted() {
    const canvas = this.el.querySelector("#three-canvas");
    if (!canvas) {
      console.error("Canvas element not found!");
      return;
    }
    this.renderer = new THREE.WebGLRenderer({ canvas });
    this.renderer.setSize(canvas.clientWidth, canvas.clientHeight);

    // Scene setup
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, canvas.clientWidth / canvas.clientHeight, 0.1, 4000);
    this.camera.position.set(0, 0, 0);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.enablePan = true;
    this.controls.enableRotate = true;
    this.controls.enableZoom = true;
    this.controls.dampingFactor = 0.05;
    this.controls.screenSpacePanning = false;
    this.controls.minDistance = 5;
    this.controls.maxDistance = 80000;
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

    this.handleEvent("grid_update", (payload) => {
        this.updateGridGeometry(payload.grid)
    })

    this.sphereMeshes = {};
    this.traces = {};

    // Render celestial bodies
    const bodies = JSON.parse(this.el.dataset.simulation)
    this.group = new THREE.Group();
    this.scene.add(this.group);
    bodies.forEach(body => {
      const geometry = new THREE.SphereGeometry(body.radius, 6, 4);
      const material = new THREE.MeshBasicMaterial({ color: body.color });
      const sphere = new THREE.Mesh(geometry, material);
      sphere.position.set(
        body.pos[0] * AU_SCALE,
        body.pos[1] * AU_SCALE,
        body.pos[2] * AU_SCALE,
      );
      this.group.add(sphere);
    
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

  updated() {
      this.updateSimultationData();
      this.addButtonListeners();
  },

  updateGridGeometry(gridData) {
      if (this.gridMesh) {
        this.scene.remove(this.gridMesh);
        this.gridMesh.geometry.dispose();
        this.gridMesh.material.dispose();
        this.gridMesh = null;
      }
  
      const geometry = new THREE.BufferGeometry();
      const vertices = [];
  
      gridData.forEach(([x, y, z]) => {
        if (!Array.isArray([x, y, z]) || [x, y, z].length !== 3) {
          console.error(`Invalid point at index ${index}:`, [x, y, z]);
        } else if ([x, y, z].some(isNaN)) {
          console.error(`NaN detected in point ${index}:`, [x, y, z]);
        } else {
          vertices.push([x, y, z][0] * AU_SCALE, [x, y, z][1] * AU_SCALE, [x, y, z][2] * AU_SCALE);
        }
      });
      // console.log("Processed Vertices:", vertices.length);
      
      const cleanVertices = vertices.filter(n => !isNaN(n));  // Remove NaNs
      
      if (cleanVertices.length % 3 !== 0) {
        console.error("Data is missing. The final vertex list is not divisible by 3.");
      }
      
      geometry.setAttribute('position', new THREE.Float32BufferAttribute(cleanVertices, 3));

      const material = new THREE.PointsMaterial({ size: 0.2, color: 0x808080 });
      this.gridMesh = new THREE.Points(geometry, material);
  
      this.scene.add(this.gridMesh);
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
          // console.log(`${body.id} - Position: ${pos}:`, body.id, pos);
          this.traces[body.id].positions.push(pos);
          // Limit the last N positions to limit memory usage
          if (this.traces[body.id].positions.length > 2000) {
            this.traces[body.id].positions.shift();
          }
  
          let traceGeometry = new THREE.BufferGeometry().setFromPoints(this.traces[body.id].positions);
          this.traces[body.id].line.geometry.dispose();
          this.traces[body.id].line.geometry = traceGeometry;
        }
      });
  },

  animate() {
      requestAnimationFrame(this.animate.bind(this));
      this.controls.update();
      this.renderer.render(this.scene, this.camera);
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
