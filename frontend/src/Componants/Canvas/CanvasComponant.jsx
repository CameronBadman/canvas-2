import React, { useState, useCallback, useEffect, useRef } from 'react';
import { Excalidraw } from '@excalidraw/excalidraw';
import { debounce } from 'lodash';
import process from 'process';

const CanvasComponent = () => {
  const [elements, setElements] = useState([]);
  const [appState, setAppState] = useState({});
  const previousElementsRef = useRef([]);
  
  const ws = useRef(null);
  
  useEffect(() => {
    ws.current = new WebSocket("ws://localhost:4000/123456789")
    
    ws.current.onopen = () => {}



    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        console.log(data)
      } catch {
        console.log("error failed to parse ws data")
      }
    }

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
    
    ws.current.onclose = () => {
      console.log('WebSocket disconnected');
    };

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };

  }, [])

  const sendMessage = (message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(message);
    }
  };

  const handleChange = debounce((elements, appState) => {
    const changedElements = elements.filter(element => {
      const prevElement = previousElementsRef.current.find(prev => prev.id === element.id);
      return !prevElement || prevElement.version !== element.version;
    });
    
    const newElements = elements.filter(element => 
      !previousElementsRef.current.find(prev => prev.id === element.id)
    );

    if (changedElements.length > 0 || newElements.length > 0) {
    sendMessage(JSON.stringify(changedElements));
    }

    previousElementsRef.current = elements;
  }, 100);

  useEffect(() => {
  }, [elements, appState]); 

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <Excalidraw
        initialData={{ elements, appState }}
        onChange={handleChange}
      />
    </div>
  );
};

export default CanvasComponent;
