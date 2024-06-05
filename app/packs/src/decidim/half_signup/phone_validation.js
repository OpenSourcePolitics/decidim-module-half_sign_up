$(() => {
    const updateButtonState = () => {

        if ($("#sms_auth_phone_country").val() === "FR") {
            $(".button").prop("disabled", true);

            $("#sms_auth_phone_number").on('input', function() {
                const phoneNumber = $(this).val();
                if ((phoneNumber.charAt(0) === "0" && phoneNumber.length === 10) || (phoneNumber.charAt(0) !== "0" && phoneNumber.length === 9)) {
                    const regex = /^(0[67]|[67])\d{8}$/;

                    if (regex.test(phoneNumber)) {
                        console.log("valid number");
                        $(".button").prop("disabled", false);
                    } else {
                        console.log("unvalid number");
                        const phoneNumberError = $("#sms_auth_phone_number").siblings("span.form-error");
                        console.log(phoneNumberError)
                        console.log(phoneNumberError.addClass('is-visible'))
                        phoneNumberError.addClass('is-visible').html('Is not valid, it must start with 06 or 07 and contain 10 digits');
                    }
                } else {
                    $(".button").prop("disabled", true);
                }
            });

        } else {
                    $(".button").prop("disabled", false);
                    $("#sms_auth_phone_number").off('input');
                }
    };

    updateButtonState()

    $("#sms_auth_phone_country").change( function(){
        console.log($("#sms_auth_phone_country").val())

        updateButtonState()
    })
})

