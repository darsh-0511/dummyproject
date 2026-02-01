import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import App from './App'
import axios from 'axios'
import { vi } from 'vitest'

vi.mock('axios')

const mockSeats = [
  { id: 1, status: 'available', price: 5 },
  { id: 2, status: 'occupied', price: 5 },
]

describe('Blu-Reserve Frontend Tests', () => {

  beforeEach(() => {
    axios.get.mockResolvedValue({ data: mockSeats })
    vi.spyOn(window, 'alert').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })


  // Render Test
  
  test('renders login screen initially', () => {
    render(<App />)
    expect(screen.getByText(/Blu-Reserve/i)).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/w3 ID/i)).toBeInTheDocument()
  })

  //Login Validation Test
  
  test('rejects non-IBM email login', () => {
    render(<App />)

    fireEvent.change(screen.getByPlaceholderText(/w3 ID/i), {
      target: { value: 'user@gmail.com' }
    })

    fireEvent.click(screen.getByText(/Sign In/i))

    expect(window.alert).toHaveBeenCalled()
  })

  
  //API Fetch + Seat Render
  
  test('fetches and displays seats after login', async () => {
    render(<App />)

    fireEvent.change(screen.getByPlaceholderText(/w3 ID/i), {
      target: { value: 'user@ibm.com' }
    })
    fireEvent.click(screen.getByText(/Sign In/i))

    expect(await screen.findByRole('button', { name: '1' })).toBeInTheDocument()
    expect(await screen.findByRole('button', { name: '2' })).toBeInTheDocument()
  })

  
  //Seat Selection (FIXED)
  test('selecting a seat updates booking summary', async () => {
    render(<App />)

    fireEvent.change(screen.getByPlaceholderText(/w3 ID/i), {
      target: { value: 'user@ibm.com' }
    })
    fireEvent.click(screen.getByText(/Sign In/i))

    const seatButton = await screen.findByRole('button', { name: '1' })
    fireEvent.click(seatButton)

    // Assert via booking summary context
    expect(screen.getByText(/Seat Number/i)).toBeInTheDocument()

    const seatNumber = screen
      .getByText(/Seat Number/i)
      .parentElement
      .querySelector('p:nth-child(2)')

    expect(seatNumber).toHaveTextContent('1')
  })
 
  //Booking Failure Handling
 
  test('shows error when booking fails', async () => {
    axios.post.mockRejectedValueOnce(new Error('Booking failed'))

    render(<App />)

    fireEvent.change(screen.getByPlaceholderText(/w3 ID/i), {
      target: { value: 'user@ibm.com' }
    })
    fireEvent.click(screen.getByText(/Sign In/i))

    const seatButton = await screen.findByRole('button', { name: '1' })
    fireEvent.click(seatButton)

    fireEvent.click(screen.getByText(/Confirm/i))

    await waitFor(() => {
      expect(screen.getByText(/Booking Failed/i)).toBeInTheDocument()
    })
  })
})
