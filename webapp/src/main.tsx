import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { createServices } from './services/createServices'
import { WebAudio } from './services/audio'
import { BrowserDevice } from './services/device'
import './index.css'

const services = createServices(new WebAudio(), new BrowserDevice())

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App services={services} />
  </StrictMode>,
)
