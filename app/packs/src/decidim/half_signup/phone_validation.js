$(() => {

    const phoneValidationRegex = () => {
        const regex = /^(0[67]|[67])\d{8}$/;
        const phoneNumberError = $("#sms_auth_phone_number").siblings("span.form-error").addClass('is-visible');
        if (regex.test(phoneNumber)) {
            phoneNumberError.html($("#phone_number_invalid_message").attr("hidden", true));
            $(".button").prop("disabled", false);
        } else {
            phoneNumberError.html($("#phone_number_invalid_message").text());
        }
    }
    const updateButtonState = () => {

        if ($("#sms_auth_phone_country").val() === "FR" ) {
            $(".button").prop("disabled", true);
            $("#sms_auth_phone_number").attr("placeholder", "0621212121");

            $("#sms_auth_phone_number").on('input', function() {
                const phoneNumber = $(this).val();
                if ((phoneNumber.charAt(0) === "0" && phoneNumber.length === 10) || (phoneNumber.charAt(0) !== "0" && phoneNumber.length === 9)) {

                    phoneValidationRegex()

                } else {
                    $(".button").prop("disabled", true);
                }
            });

        } else {
                    $(".button").prop("disabled", false);
                    $("#sms_auth_phone_number").off('input');
                    $("#sms_auth_phone_number").attr("placeholder", "");
                }
    };

    updateButtonState()

    $("#sms_auth_phone_country").change( function(){
        updateButtonState()
    })
})

