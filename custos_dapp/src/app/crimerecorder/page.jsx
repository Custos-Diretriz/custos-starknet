'use client'
import { useState, useEffect } from "react";
//import Navbar from "@/components/navbar";
import { NFTStorage } from "nft.storage";

const Recorder = () => {
  const [selectedMedia, setSelectedMedia] = useState(null);
  const [chunks, setChunks] = useState([]);
  const [mediaRecorder, setMediaRecorder] = useState(null);
  const [mediaStream, setMediaStream] = useState(null);
  const [videoUrl, setVideoUrl] = useState(null);
  const [imageUrl, setImageUrl] = useState(null);
  const [isFrontCamera, setIsFrontCamera] = useState(true);

  const otherRecorder = (selectedMedia) => {
    return selectedMedia === "vid" ? "aud" : "vid";
  };
  const NFT_STORAGE_TOKEN =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDAxMmMyMDQxOTMxZjBCMTk5MjRFNjk4NjcxMDE0YzJjYjY4RWNGNjMiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTcwNzc0NjU2NTkxMCwibmFtZSI6IkN5YmVyICJ9.AvvSAu9TIQV5uXXpWZ68c_0j0RGbNbc69aBjDzFDPIs";
  const clients = new NFTStorage({ token: NFT_STORAGE_TOKEN });

  const handleMediaChange = (e) => {
    const selectedMedia = e.target.value;
    setSelectedMedia(selectedMedia);
    document.getElementById(`${selectedMedia}-recorder`).style.display =
      "block";
    document.getElementById(
      `${otherRecorder(selectedMedia)}-recorder`
    ).style.display = "none";
  };

  const startRecording = (thisButton, otherButton) => {
    const constraints = {
      video: { facingMode: isFrontCamera ? 'user' : 'environment' },
      audio: true,
    };

    navigator.mediaDevices
      .getUserMedia(constraints)
      .then((mediaStream) => {
        const video = document.getElementById("web-cam-container");
        video.srcObject = mediaStream;
        setMediaStream(mediaStream);

        document.getElementById("vid-recorder").style.display = "block";
        document.getElementById("vid-record-status").innerText =
          'Click the "Stop" button to stop recording';

        thisButton.disabled = true;
        otherButton.disabled = false;

        const mediaRecorder = new MediaRecorder(mediaStream);
        setMediaRecorder(mediaRecorder);

        mediaRecorder.start();

        mediaRecorder.onstop = () => {
          const videoBlob = new Blob(chunks, { type: "video/webm" });
          const videoUrl = URL.createObjectURL(videoBlob);
          mediaRecorder.stop();
          setVideoUrl(videoUrl);
        };

        mediaRecorder.ondataavailable = (event) => {
          chunks.push(event.data);
        };
      })
      .catch((err) => {
        console.error("Error accessing camera:", err);
      });
  };

  const stopRecording = async () => {
    if (mediaRecorder.state === "recording") {
      mediaRecorder.stop();
      document.getElementById("vid-recorder").style.display = "none";
      document.getElementById("vid-record-status").innerText =
        'Click the "Start" button to start recording';

      try {
        // Convert recorded chunks to a single Blob
        const videoBlob = new Blob(chunks, { type: "video/webm" });

        // Create FormData object and append the video Blob to it
        const formData = new FormData();
        formData.append("file", videoBlob, "recorded-video.webm"); // Ensure correct field name ('file')

        // Send FormData to the backend using fetch or Axios
        const response = await fetch("https://api.nft.storage/upload", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${NFT_STORAGE_TOKEN}`,
          },
          body: formData,
        });

        if (response.ok) {
          const data = await response.json();
          const cid = data.value.cid;
          console.log(cid);
          localStorage.setItem("video_uri", cid);
          setUri(cid);
          console.log(uri);
          await handleSubmit();
          alert("File uploaded successfully!");
        } else {
          // Handle upload failure
          console.error("Failed to upload video");
        }
      } catch (error) {
        console.error("Error uploading video:", error);
      }
      window.location.reload();
    }
  };

  const takePicture = async () => {
    const video = document.getElementById("web-cam-container");
    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext("2d").drawImage(video, 0, 0, canvas.width, canvas.height);
    const imageDataUrl = canvas.toDataURL();
    setImageUrl(imageDataUrl);
    document.getElementById("download-image").style.display = "block";

    try {
      // Convert the captured image to a Blob
      const blob = await fetch(imageDataUrl).then((res) => res.blob());

      // Create FormData object and append the image blob to it
      const formData = new FormData();
      formData.append("file", blob, "captured-image.png"); // 'file' should match the key expected by the backend

      // Send FormData to IPFS using fetch
      const response = await fetch("https://api.nft.storage/upload", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${NFT_STORAGE_TOKEN}`,
        },
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        const cid = data.value.cid;
        console.log(cid);
        localStorage.setItem("image_uri", cid);
        setUri(cid);
        console.log(uri);

        await handleSubmit();
        alert("Image uploaded successfully!");
      } else {
        console.error("Failed to upload image");
      }
    } catch (error) {
      console.error("Error uploading image:", error);
    }
  };

  const toggleCamera = () => {
    setIsFrontCamera(!isFrontCamera);
    if (mediaStream) {
      mediaStream.getTracks().forEach((track) => track.stop());
    }
    document.getElementById("start-vid-recording").disabled = false;
    document.getElementById("stop-vid-recording").disabled = true;
  };

  useEffect(() => {
    if (videoUrl) {
      const downloadLink = document.createElement("a");
      downloadLink.href = videoUrl;
      downloadLink.download = "recorded-video.webm";
      document.body.appendChild(downloadLink);
      downloadLink.click();
      document.body.removeChild(downloadLink);
    }
  }, [videoUrl]);

  useEffect(() => {
    if (imageUrl) {
      const downloadLink = document.createElement("a");
      downloadLink.href = imageUrl;
      downloadLink.download = "captured-image.png";
      document.body.appendChild(downloadLink);
      downloadLink.click();
      document.body.removeChild(downloadLink);
    }
  }, [imageUrl]);

  return (
    <div>
      {/* <Navbar /> */}
      <div className="flex flex-col items-center justify-center h-screen border-2 mx-auto border-[#baa] my-10 bg-[#090909]">
        <div className="display-none" id="vid-recorder">
          <h3>Record Video</h3>
          <video
            autoPlay
            id="web-cam-container"
            className="mb-4"
            style={{ backgroundColor: "white" }}
          >
            Your browser doesn't support the video tag
          </video>

          <div className="recording mb-4" id="vid-record-status">
            Click the "Start" button to start capturing
          </div>

          <button
            type="button"
            id="start-vid-recording"
            onClick={(e) =>
              startRecording(
                e.target,
                document.getElementById("stop-vid-recording")
              )
            }
            className="bg-[#c92eff] w-fit rounded-lg hover:bg-[#090909] text-white font-bold py-2 px-4 border-2 border-[#c92eff] font-san hover:border-[#c92eff]"
          >
            Start
          </button>

          <button
            type="button"
            id="take-picture"
            onClick={takePicture}
            className="bg-[#c92eff] w-fit rounded-lg hover:bg-[#090909] text-white mx-3 font-bold py-2 px-4 border-2 border-[#c92eff] font-san hover:border-[#c92eff]"
          >
            Take Picture
          </button>

          <button
            type="button"
            id="stop-vid-recording"
            onClick={stopRecording}
            className="bg-[#c92eff] w-fit  rounded-lg hover:bg-[#090909] text-white font-bold py-2 px-4 border-2 border-[#c92eff] font-san hover:border-[#c92eff]"
          >
            Stop
          </button>

          <button
            type="button"
            id="toggle-camera"
            onClick={toggleCamera}
            className="bg-[#c92eff] w-fit rounded-lg hover:bg-[#090909] text-white font-bold py-2 px-4 border-2 border-[#c92eff] font-san hover:border-[#c92eff] my-2"
          >
            Toggle Camera
          </button>

          <a
            id="download-video"
            style={{ display: "none" }}
            href={videoUrl}
            download="recorded-video.webm"
          >
            Download Video
          </a>
          <a
            id="download-image"
            style={{ display: "none" }}
            href={imageUrl}
            download="captured-image.png"
          >
            Download Image
          </a>
        </div>
      </div>
    </div>
  );
};

export default Recorder;
