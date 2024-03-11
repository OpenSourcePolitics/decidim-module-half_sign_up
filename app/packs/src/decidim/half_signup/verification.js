$(() => {
  const verificationInputs = document.querySelectorAll("#verification input[type='number']");
  const verificationForm = document.querySelector("#verification").closest("form");
  verificationInputs.forEach((input, ind) => {
    input.setAttribute("maxlength", "1");
    input.addEventListener("click", () => {
      input.select();
    })
    input.addEventListener("input", (event) => {
      event.preventDefault();

      const valueToInsert = event.data;
      const val = input.value.trim();

      if (val.length > 1) {
        input.value = val.substr(0, 1);
      }

      if (valueToInsert === null || valueToInsert.trim() === "") {
        return
      }

      if (valueToInsert.length > 1 && val === "") {
        let jj = 0;
        for (let ii = ind; ii < verificationInputs.length; ii += 1) {
          if (jj > valueToInsert.length) {
            return;
          }
          if (valueToInsert.substr(jj, 1)) {
            verificationInputs[ii].value = valueToInsert.substr(jj, 1);
            verificationInputs[ii].focus();
            jj += 1
          }
        }
      } else {
        if (!(/\d/).test(valueToInsert)) {
          input.value = ""
          return
        }
        if (verificationInputs[ind].value.trim().length > 0) {
          verificationInputs[ind].value = valueToInsert;
        }

        const nextInput = verificationInputs[ind + 1];

        if (nextInput) {
          nextInput.focus();
          nextInput.select();
        } else {
          verificationForm.querySelector("button[type='submit']").focus();
        }
      }
    })

    input.addEventListener("paste", (event) => {
      const clipboardData = event.clipboardData || window.clipboardData;
      const pastedData = clipboardData.getData("text").trim();
      // find the first empty input field and paste the data there
      let jj = 0;
      for (let ii = ind; ii < verificationInputs.length; ii += 1) {
        if (jj > pastedData.length) {
          return;
        }
        if (pastedData.substr(jj, 1)) {
          verificationInputs[ii].value = pastedData.substr(jj, 1);
          verificationInputs[ii].focus();
          jj += 1
        }
      }
    });
  });
  const fieldsvalid = () => {
    let allFieldsFilled = true;
    verificationInputs.forEach((input) => {
      if (input.value.trim() === "") {
        allFieldsFilled = false;
      }
    });
    return allFieldsFilled
  };

  const togglevalidity = (item) => {
    if (item.classList.contains("is-invisible")) {
      item.classList.remove("is-invisible")
      item.classList.add("is-visible")
    } else {
      item.classList.remove("is-visible")
      item.classList.add("is-invisible")
    }
  }

  const setVerificationField = () => {
    let combinedValue = "";
    verificationInputs.forEach((input) => {
      combinedValue += input.value.trim();
    });
    document.querySelector('input[name="verification_code[verification]"]').value = combinedValue
  };

  const makeFieldsInvalid = () => {
    verificationInputs.forEach((input) => {
      input.classList.add("is-invalid-input")
    })
    togglevalidity(document.querySelector("#verification-error"))
  }

  const form = document.querySelector(".new_verification_code");
  $(form).on("submit", (ev) => {
    setVerificationField();
    if (fieldsvalid()) {
      return;
    }

    ev.preventDefault();
    makeFieldsInvalid();
  });
})
