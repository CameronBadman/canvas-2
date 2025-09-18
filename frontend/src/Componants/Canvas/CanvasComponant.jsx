import React, { useState, useCallback, useEffect, useRef } from 'react';
import { Tldraw } from 'tldraw';
import 'tldraw/tldraw.css';
import { debounce } from 'lodash';

const CanvasComponent = () => {
  const ws = useRef(null);
  
  useEffect(() => {
    ws.current = new WebSocket("ws://localhost:4000/123456789");
    
    ws.current.onopen = () => {
      console.log('WebSocket connected');
    };
    
    ws.current.onmessage = (event) => {
      try {
        console.log('Received WebSocket message:', event.data);
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
      ws.current.send(message.changes);
    }
  }, []);

  const extractRelevantChanges = (change) => {
    console.log('ALL CHANGES:', change);
    
    // Log every single record that's being updated
    Object.entries(change.changes.updated).forEach(([id, [from, to]]) => {
      console.log(`ID: ${id}`);
      console.log(`TypeName: ${to.typeName}`);
      console.log(`Type: ${to.type}`);
      console.log(`Record:`, to);
      console.log('---');
    });
    
    return 0;
  }
  
  const handleStoreChange = useCallback(
    debounce((change) => {
      const relevantChanges = extractRelevantChanges(change);
      if (relevantChanges.length > 0) {
        sendMessage(JSON.stringify(relevantChanges));
      }
    }, 200), 
    [sendMessage]
  );
  
  const handleMount = useCallback((editor) => {
    console.log('Tldraw editor mounted');
    
    const cleanup = editor.store.listen(handleStoreChange, { 
      source: 'user' 
    });
    
    return cleanup;
  }, [handleStoreChange]);
  
  return (
    <div style={{ width: '100%', height: '100%' }}>
      <Tldraw
        onMount={handleMount}
      />
    </div>
  );
};

export default CanvasComponent;
