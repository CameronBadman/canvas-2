import { useState, useCallback, useEffect, useRef } from 'react';
import { Excalidraw, CaptureUpdateAction } from '@excalidraw/excalidraw';
import { debounce } from 'lodash';
import { useParams } from 'react-router-dom';

const CanvasComponent = () => {
  const { randomId } = useParams();
  const [elements, setElements] = useState([]);
  const [appState, setAppState] = useState({});
  const [ready, setReady] = useState(false)
  
  const ws = useRef(null);
  const excalidrawAPI = useRef(null);
  const isReceivingUpdate = useRef(false);
  
  useEffect(() => {
    console.log(randomId)
    ws.current = new WebSocket("ws://localhost:4000/" + randomId);
    
    ws.current.onopen = () => {
      setReady(true)
      console.log('WebSocket connected');
    };
    
    ws.current.onmessage = (event) => {
      try {
        const incomingElements = JSON.parse(event.data);
        console.log('Received elements:', incomingElements);
        
        isReceivingUpdate.current = true;
        
        setElements(prevElements => {
          const currentElements = Array.isArray(prevElements) ? prevElements : [];
          const elementMap = new Map(currentElements.map(el => [el.id, el]));
          
          incomingElements.forEach(element => {
            elementMap.set(element.id, element);
          });
          
          const newElements = Array.from(elementMap.values());
          
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
            isReceivingUpdate.current = false;
          }, 0);
          
          return newElements;
        });
      } catch (error) {
        console.error("Failed to parse WebSocket data:", error);
        isReceivingUpdate.current = false;
      }
    };
    
    ws.current.onerror = (error) => {
      setReady(false)
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
  
  const hasElementChanged = (element, prevElement) => {
    if (!prevElement) return true;
    
    const keyProps = ['x', 'y', 'width', 'height', 'angle', 'strokeColor', 'backgroundColor', 'fillStyle', 'strokeWidth', 'text', 'version'];
    return keyProps.some(prop => element[prop] !== prevElement[prop]);
  };
  
  const sendElementUpdates = useCallback(
    debounce((currentElements) => {
      if (isReceivingUpdate.current) return;
      
      const prevElementsMap = new Map(previousElementsRef.current.map(el => [el.id, el]));
      
      const changedElements = currentElements.filter(element => {
        const prevElement = prevElementsMap.get(element.id);
        return hasElementChanged(element, prevElement);
      });
      
      if (changedElements.length > 0) {
        console.log('Sending changed elements:', changedElements.map(el => `${el.id} (${el.type}) x:${el.x} y:${el.y}`));
        sendMessage(JSON.stringify(changedElements));
      }
      
      previousElementsRef.current = currentElements;
    }, 200),
    [sendMessage]
  );
  
  const handleChange = useCallback((elements, appState) => {
    setElements(elements);
    setAppState(appState);
    sendElementUpdates(elements);
  }, [sendElementUpdates]);
  
  // Additional event listeners for more comprehensive change detection
  const handlePointerUpdate = useCallback((payload) => {
    if (payload.pointer.button === "up" && excalidrawAPI.current) {
      // Pointer released - check for changes
      const currentElements = excalidrawAPI.current.getSceneElements();
      sendElementUpdates(currentElements);
    }
  }, [sendElementUpdates]);
  
  const handleExcalidrawAPI = useCallback((api) => {
    excalidrawAPI.current = api;
    // Set up additional event listeners for better change detection
    if (api.onPointerUpdate) {
      api.onPointerUpdate(handlePointerUpdate);
    }
  }, [handlePointerUpdate]);
  
  return (
    <div style={{ width: '100%', height: '100%' }}>
      {ready ? <Excalidraw
        initialData={{ elements, appState }}
        onChange={handleChange}
        excalidrawAPI={handleExcalidrawAPI}
        onPointerUpdate={handlePointerUpdate}
      /> : <div></div>}
      
    </div>
  );
};

export default CanvasComponent;
