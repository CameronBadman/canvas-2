import { useParams } from 'react-router-dom';
import CanvasComponent from "../Componants/Canvas/CanvasComponant.jsx";

function CanvasPage(canvas_id) {
    return (
        <div className="flex h-screen w-screen overflow-hidden">
            {/* Canvas Area */}
            <div className="flex-1 relative">
                <CanvasComponent  />
            </div>
        </div>
    );
}

export default CanvasPage;

