// Copyright (c) 2018 GitHub, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

function autosize(textarea) {
  let previousValue = null
  let isUserResized = false

  let x
  let y
  let height

  function onUserResize(event) {
    if (x !== event.clientX || y !== event.clientY) {
      const newHeight = textarea.style.height
      if (height && height !== newHeight) {
        isUserResized = true
        textarea.style.maxHeight = ''
        textarea.removeEventListener('mousemove', onUserResize)
      }
      height = newHeight
    }

    x = event.clientX
    y = event.clientY
  }

  const document = textarea.ownerDocument
  const documentElement = document.documentElement

  function overflowOffset() {
    let offsetTop = 0
    let el = textarea

    while (el !== document.body && el !== null) {
      offsetTop += el.offsetTop || 0
      el = el.offsetParent
    }

    const top = offsetTop - document.defaultView.pageYOffset
    const bottom = documentElement.clientHeight - (top + textarea.offsetHeight)
    return {top, bottom}
  }

  function sizeToFit() {
    if (isUserResized) return
    if (textarea.value === previousValue) return
    if (textarea.offsetWidth <= 0 && textarea.offsetHeight <= 0) return

    const {top, bottom} = overflowOffset()
    if (top < 0 || bottom < 0) {
      return
    }

    const maxHeight = Number(getComputedStyle(textarea).height.replace(/px/, '')) + bottom
    textarea.style.maxHeight = `${maxHeight - 100}px`

    const container = textarea.parentElement
    if (container instanceof HTMLElement) {
      const containerHeight = container.style.height
      container.style.height = getComputedStyle(container).height
      textarea.style.height = 'auto'
      textarea.style.height = `${textarea.scrollHeight}px`
      container.style.height = containerHeight
      height = textarea.style.height
    }

    previousValue = textarea.value
  }

  function onFormReset() {
    isUserResized = false
    textarea.style.height = ''
    textarea.style.maxHeight = ''
  }

  textarea.addEventListener('mousemove', onUserResize)
  textarea.addEventListener('input', sizeToFit)
  textarea.addEventListener('change', sizeToFit)
  const form = textarea.form
  if (form) form.addEventListener('reset', onFormReset)
  if (textarea.value) sizeToFit()

  return {
    unsubscribe() {
      textarea.removeEventListener('mousemove', onUserResize)
      textarea.removeEventListener('input', sizeToFit)
      textarea.removeEventListener('change', sizeToFit)
      if (form) form.removeEventListener('reset', onFormReset)
    }
  }
}
