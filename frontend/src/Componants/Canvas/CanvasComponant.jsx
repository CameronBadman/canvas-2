import React, { useState, useCallback, useEffect, useRef } from 'react';
import { Excalidraw, CaptureUpdateAction } from '@excalidraw/excalidraw';
import { debounce } from 'lodash';

const CanvasComponent = () => {
  const [elements, setElements] = useState([]);
  const [appState, setAppState] = useState({});
  
  const ws = useRef(null);
  const excalidrawAPI = useRef(null);
  
  useEffect(() => {
    ws.current = new WebSocket("ws://localhost:4000/123456789");
    
    ws.current.onopen = () => {
      console.log('WebSocket connected');
    };
    
    ws.current.onmessage = (event) => {
      try {
        const incomingElements = JSON.parse(event.data);
        console.log('Received elements:', incomingElements);
        
        if (!Array.isArray(incomingElements)) {
          console.warn('Incoming elements is not an array:', incomingElements);
          return;
        }
        
        // Update elements state - let Excalidraw handle the merging
        setElements(prevElements => {
          const currentElements = Array.isArray(prevElements) ? prevElements : [];
          const elementMap = new Map(currentElements.map(el => [el.id, el]));
          
          // Add/update incoming elements
          incomingElements.forEach(element => {
            elementMap.set(element.id, element);
          });
          
          const newElements = Array.from(elementMap.values());
          
          // Update Excalidraw scene
          setTimeout(() => {
            if (excalidrawAPI.current) {
              try {
                excalidrawAPI.current.updateScene({
                  elements: newElements,
                  captureUpdate: CaptureUpdateAction.NEVER
                });
              } catch (error) {
                excalidrawAPI.current.updateScene({
                  elements: newElements,
                  commitToHistory: false
                });
              }
            }
          }, 0);
          
          return newElements;
        });
      } catch (error) {
        console.error("Failed to parse WebSocket data:", error);
      }
    };
    
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
  }, []);
  
  const sendMessage = useCallback((message) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(message);
    }
  }, []);
  
  const previousElementsRef = useRef([]);
  
  // Only send changed elements to avoid loops and reduce bandwidth
  const handleChange = useCallback(
    debounce((elements, appState) => {
      const changedElements = elements.filter(element => {
        const prevElement = previousElementsRef.current.find(prev => prev.id === element.id);
        return !prevElement || prevElement.version !== element.version;
      });
      
      const newElements = elements.filter(element => 
        !previousElementsRef.current.find(prev => prev.id === element.id)
      );
      
      const elementsToSend = [...changedElements, ...newElements];
      
      if (elementsToSend.length > 0) {
        sendMessage(JSON.stringify(elementsToSend));
      }
      
      previousElementsRef.current = elements;
      setElements(elements);
      setAppState(appState);
    }, 100),
    [sendMessage]
  );
  
  const handleExcalidrawAPI = useCallback((api) => {
    excalidrawAPI.current = api;
    console.log('Excalidraw API ready');
  }, []);
  
  return (
    <div style={{ width: '100%', height: '100%' }}>
      <Excalidraw
        initialData={{ elements, appState }}
        onChange={handleChange}
        excalidrawAPI={handleExcalidrawAPI}
      />
    </div>
  );
};

export default CanvasComponent;
