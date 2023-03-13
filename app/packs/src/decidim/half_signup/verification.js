$(() => {
  const verificationInputs = document.querySelectorAll('#verification input[type="text"]');
  verificationInputs.forEach((input, ind) => {
    input.setAttribute("maxlength", "1");
    input.addEventListener("click", () => {
      input.select();
    })
    input.addEventListener("input", () => {
      const val = input.value

      if (!(/\d/).test(val)) {
        input.value = ""
        return
      }
      const nextInput = verificationInputs[ind + 1];

      if (nextInput) {
        nextInput.focus();
        nextInput.select();
      }else{
        input.blur();
      }
    })
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
    togglevalidity(document.querySelector("#zip-code-error"))
  }

  const form = document.querySelector(".new_user_data");
  $(form).on("submit", (ev) => {
    setVerificationField();
    if (fieldsvalid()) {
      return;
    }

    ev.preventDefault();
    makeFieldsInvalid();
  });
})
